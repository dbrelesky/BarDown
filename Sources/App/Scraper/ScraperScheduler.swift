import Vapor
import Fluent
import NIOCore

/// Orchestrates scraping of D1 lacrosse data on a smart schedule.
///
/// Scheduling logic:
/// - **Live games detected**: Scrape that conference every 30 seconds
/// - **Game day active hours** (noon-midnight ET): Scrape every 5 minutes
/// - **Off hours / no games**: Scrape every 30 minutes
///
/// The scheduler uses NIO's RepeatedTask for the base timer (simpler than VaporCron
/// for dynamic interval adjustment). It checks game state in the database to decide
/// which conferences need aggressive polling.
///
/// Overlap prevention: An actor-based `isRunning` flag prevents concurrent scrape jobs.
actor ScraperScheduler {
    private let app: Application
    private let ncaaScraper: NCAAAPIScraper
    private let statBroadcastScraper: StatBroadcastScraper
    private let reconciler: DataReconciler

    /// Whether a scrape cycle is currently in progress.
    private var isRunning = false

    /// The base check interval in seconds. The scheduler runs at this interval
    /// and decides what to scrape based on current state.
    private let baseCheckInterval: TimeAmount = .seconds(30)

    /// Phase 1 conferences with their NCAA API names for filtering.
    private let phase1Conferences: [(abbreviation: String, ncaaName: String)] = [
        ("ACC", "ACC"),
        ("BIGEAST", "Big East"),
        ("B1G", "Big Ten"),
        ("PATRIOT", "Patriot"),
        ("IVY", "Ivy League")
    ]

    /// Tracks when each conference was last scraped.
    private var lastScrapeTime: [String: Date] = [:]

    /// Tracks which conferences currently have live games.
    private var liveConferences: Set<String> = []

    init(app: Application) {
        self.app = app
        self.ncaaScraper = NCAAAPIScraper(app: app)
        self.statBroadcastScraper = StatBroadcastScraper(app: app)
        self.reconciler = DataReconciler(app: app)
    }

    // MARK: - Lifecycle

    /// Starts the scraper scheduler. Should be called from configure.swift on app boot.
    func start() {
        app.logger.info("ScraperScheduler: Starting with \(phase1Conferences.count) Phase 1 conferences")

        // Schedule the base timer using eventLoop
        let eventLoop = app.eventLoopGroup.next()
        eventLoop.scheduleRepeatedTask(
            initialDelay: .seconds(5), // Small delay to let app finish booting
            delay: baseCheckInterval
        ) { [weak self] task in
            guard let self = self else {
                task.cancel()
                return
            }
            Task {
                await self.tick()
            }
        }

        app.logger.info("ScraperScheduler: Scheduled with \(baseCheckInterval.nanoseconds / 1_000_000_000)s base interval")
    }

    // MARK: - Core Loop

    /// Called every base interval. Decides what to scrape based on current state.
    private func tick() async {
        guard !isRunning else {
            app.logger.debug("ScraperScheduler: Skipping tick — previous scrape still running")
            return
        }

        isRunning = true
        defer { isRunning = false }

        let startTime = Date()
        app.logger.debug("ScraperScheduler: Tick at \(startTime)")

        do {
            // Step 1: Check what needs scraping
            let now = Date()
            let isActiveHours = isWithinActiveHours(now)

            // Step 2: Detect live games from database
            try await detectLiveGames()

            // Step 3: Scrape based on priority
            for conf in phase1Conferences {
                let interval = scrapeInterval(for: conf.abbreviation, isActiveHours: isActiveHours)
                let lastScrape = lastScrapeTime[conf.abbreviation]

                if let lastScrape = lastScrape {
                    let elapsed = now.timeIntervalSince(lastScrape)
                    if elapsed < interval {
                        continue // Not time to scrape this conference yet
                    }
                }

                await scrapeConference(conf, date: now)
                lastScrapeTime[conf.abbreviation] = now
            }

            let duration = Date().timeIntervalSince(startTime)
            app.logger.info("ScraperScheduler: Tick completed in \(String(format: "%.1f", duration))s")

        } catch {
            app.logger.error("ScraperScheduler: Tick failed: \(error)")
        }
    }

    // MARK: - Scraping

    /// Scrapes a single conference using NCAA API (primary) with StatBroadcast fallback.
    private func scrapeConference(_ conf: (abbreviation: String, ncaaName: String), date: Date) async {
        let startTime = Date()

        // Primary: NCAA API
        let ncaaGames = await ncaaScraper.fetchScoreboard(date: date, conference: conf.ncaaName)

        if !ncaaGames.isEmpty {
            do {
                let result = try await reconciler.reconcileGames(scraped: ncaaGames, on: app.db)
                let duration = Date().timeIntervalSince(startTime)
                let durationStr = String(format: "%.1f", duration)
                app.logger.info(
                    "ScraperScheduler: [\(conf.abbreviation)] NCAA scraped \(ncaaGames.count) games (created: \(result.created), updated: \(result.updated)) in \(durationStr)s"
                )
            } catch {
                app.logger.error("ScraperScheduler: [\(conf.abbreviation)] Reconciliation failed: \(error)")
            }
        } else {
            app.logger.debug("ScraperScheduler: [\(conf.abbreviation)] No games from NCAA API for \(date)")
        }

        // Secondary: StatBroadcast (supplements NCAA data, especially for box scores)
        let sbGames = await statBroadcastScraper.scrapeScoreboard(conferenceAbbreviation: conf.abbreviation)
        if !sbGames.isEmpty {
            do {
                try await reconciler.reconcileGames(scraped: sbGames, on: app.db)
                app.logger.info("ScraperScheduler: [\(conf.abbreviation)] StatBroadcast supplemented with \(sbGames.count) games")
            } catch {
                app.logger.warning("ScraperScheduler: [\(conf.abbreviation)] StatBroadcast reconciliation failed: \(error)")
            }
        }

        // Box scores: fetch player-level stats for live/final games with StatBroadcast IDs
        await scrapeBoxScores(for: conf.abbreviation)
    }

    // MARK: - Box Score Scraping

    /// Scrapes box score data (player stats, quarter scores) for live and final games
    /// in the given conference that have a StatBroadcast external ID.
    ///
    /// Each game is scraped independently so one failure doesn't block others.
    /// Games that already have player stats are skipped to avoid redundant scraping.
    ///
    /// - Parameter conferenceAbbreviation: Internal conference abbreviation (e.g., "ACC")
    private func scrapeBoxScores(for conferenceAbbreviation: String) async {
        let confID = StatBroadcastScraper.conferenceIDs[conferenceAbbreviation]?.first
            ?? conferenceAbbreviation.lowercased()

        do {
            // Query games that are live or final, have a StatBroadcast ID,
            // and belong to a team in this conference
            let games = try await Game.query(on: app.db)
                .group(.or) { group in
                    group.filter(\.$status == "live")
                    group.filter(\.$status == "final")
                }
                .filter(\.$statBroadcastID != nil)
                .with(\.$homeTeam) { team in
                    team.with(\.$conference)
                }
                .with(\.$playerStats)
                .all()

            // Filter to games in this conference
            let conferenceGames = games.filter { game in
                game.homeTeam.conference.abbreviation == conferenceAbbreviation
            }

            guard !conferenceGames.isEmpty else { return }

            var scraped = 0
            for game in conferenceGames {
                // Skip games that already have player stats
                if !game.playerStats.isEmpty {
                    continue
                }

                guard let gameID = game.id,
                      let statBroadcastID = game.statBroadcastID else {
                    continue
                }

                do {
                    let boxScore = await statBroadcastScraper.scrapeBoxScore(
                        gameID: statBroadcastID,
                        confID: confID
                    )

                    if let boxScore = boxScore {
                        try await reconciler.reconcileBoxScore(
                            boxScore,
                            gameID: gameID,
                            homeTeamID: game.$homeTeam.id,
                            awayTeamID: game.$awayTeam.id,
                            on: app.db
                        )
                        scraped += 1
                    }
                } catch {
                    app.logger.warning(
                        "ScraperScheduler: [\(conferenceAbbreviation)] Box score failed for game \(statBroadcastID): \(error)"
                    )
                }
            }

            if scraped > 0 {
                app.logger.info(
                    "ScraperScheduler: [\(conferenceAbbreviation)] Scraped \(scraped) box scores"
                )
            }
        } catch {
            app.logger.warning(
                "ScraperScheduler: [\(conferenceAbbreviation)] Box score query failed: \(error)"
            )
        }
    }

    // MARK: - Scheduling Logic

    /// Determines the appropriate scrape interval for a conference.
    ///
    /// - Returns: Interval in seconds between scrapes
    private func scrapeInterval(for conference: String, isActiveHours: Bool) -> TimeInterval {
        // Live games: every 30 seconds
        if liveConferences.contains(conference) {
            return 30
        }

        // Active hours with games today: every 5 minutes
        if isActiveHours {
            return 300 // 5 minutes
        }

        // Off hours: every 30 minutes
        return 1800 // 30 minutes
    }

    /// Checks if the current time is within active game hours (noon-midnight ET).
    private func isWithinActiveHours(_ date: Date) -> Bool {
        let eastern = TimeZone(identifier: "America/New_York")!
        var calendar = Calendar.current
        calendar.timeZone = eastern
        let hour = calendar.component(.hour, from: date)
        return hour >= 12 // noon to midnight
    }

    /// Queries the database to find which conferences have live games.
    private func detectLiveGames() async throws {
        liveConferences.removeAll()

        let liveGames = try await Game.query(on: app.db)
            .filter(\.$status == "live")
            .with(\.$homeTeam) { team in
                team.with(\.$conference)
            }
            .all()

        for game in liveGames {
            let confAbbrev = game.homeTeam.conference.abbreviation
            liveConferences.insert(confAbbrev)
        }

        if !liveConferences.isEmpty {
            app.logger.info("ScraperScheduler: Live conferences: \(liveConferences.sorted().joined(separator: ", "))")
        }
    }
}
