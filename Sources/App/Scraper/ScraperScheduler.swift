import Vapor
import Fluent
import NIOCore

/// Orchestrates scraping of D1 lacrosse data on a smart schedule.
///
/// Scheduling logic:
/// - **Live games detected**: Scrape every 30 seconds
/// - **Game day active hours** (noon-midnight ET): Scrape every 5 minutes
/// - **Off hours / no games**: Scrape every 30 minutes
///
/// The scheduler fetches ALL D1 games in a single NCAA API call per cycle (no
/// conference filtering). Per-conference StatBroadcast box score scraping is
/// retained for future use once those endpoints are verified.
///
/// Overlap prevention: An actor-based `isRunning` flag prevents concurrent scrape jobs.
actor ScraperScheduler {
    private let app: Application
    private let ncaaScraper: NCAAAPIScraper
    private let statBroadcastScraper: StatBroadcastScraper
    private let reconciler: DataReconciler

    /// Whether a scrape cycle is currently in progress.
    private var isRunning = false

    /// The base check interval in seconds.
    private let baseCheckInterval: TimeAmount = .seconds(30)

    /// All D1 conferences for StatBroadcast box score scraping (future use).
    private let d1Conferences: [(abbreviation: String, ncaaName: String)] = [
        ("ACC", "ACC"),
        ("BIGEAST", "Big East"),
        ("B1G", "Big Ten"),
        ("PATRIOT", "Patriot"),
        ("IVY", "Ivy League"),
        ("CAA", "CAA"),
        ("MAAC", "MAAC"),
        ("AE", "America East"),
        ("A10", "Atlantic 10"),
        ("NEC", "NEC"),
        ("SOCON", "SoCon"),
        ("ASUN", "ASUN")
    ]

    /// Tracks when the last all-games scrape ran.
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
        app.logger.info("ScraperScheduler: Starting — scraping all D1 conferences")

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

            // Step 3: Scrape all D1 games in a single call
            let interval = scrapeInterval(isActiveHours: isActiveHours)
            let lastScrape = lastScrapeTime["all"]

            if let lastScrape = lastScrape {
                let elapsed = now.timeIntervalSince(lastScrape)
                if elapsed < interval {
                    let remaining = Int(interval - elapsed)
                    app.logger.debug("ScraperScheduler: Skipping — next scrape in \(remaining)s")
                    return
                }
            }

            await scrapeAllGames(date: now)
            lastScrapeTime["all"] = now

            let duration = Date().timeIntervalSince(startTime)
            app.logger.info("ScraperScheduler: Tick completed in \(String(format: "%.1f", duration))s")

        } catch {
            app.logger.error("ScraperScheduler: Tick failed: \(error)")
        }
    }

    // MARK: - Scraping

    /// Fetches ALL D1 lacrosse games for the given date in a single NCAA API call,
    /// then reconciles with the database. No conference filtering.
    private func scrapeAllGames(date: Date) async {
        let startTime = Date()

        let ncaaGames = await ncaaScraper.fetchScoreboard(date: date)

        if !ncaaGames.isEmpty {
            do {
                let result = try await reconciler.reconcileGames(scraped: ncaaGames, on: app.db)
                let duration = Date().timeIntervalSince(startTime)
                let durationStr = String(format: "%.1f", duration)
                app.logger.info(
                    "ScraperScheduler: NCAA scraped \(ncaaGames.count) games (created: \(result.created), updated: \(result.updated)) in \(durationStr)s"
                )
            } catch {
                app.logger.error("ScraperScheduler: Reconciliation failed: \(error)")
            }
        } else {
            app.logger.info("ScraperScheduler: No games from NCAA API for \(date)")
        }
    }

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

    /// Determines the appropriate scrape interval for the all-games cycle.
    ///
    /// - Returns: Interval in seconds between scrapes
    private func scrapeInterval(isActiveHours: Bool) -> TimeInterval {
        // Live games anywhere: every 30 seconds
        if !liveConferences.isEmpty {
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

// MARK: - Application Storage

extension Application {
    private struct ScraperSchedulerKey: StorageKey {
        typealias Value = ScraperScheduler
    }

    var scraperScheduler: ScraperScheduler? {
        get { storage[ScraperSchedulerKey.self] }
        set { storage[ScraperSchedulerKey.self] = newValue }
    }
}
