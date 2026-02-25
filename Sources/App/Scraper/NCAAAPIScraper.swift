import Vapor

/// Scrapes game data from the NCAA's public Casablanca JSON API.
///
/// ## Verified Endpoints (2026-02-24)
///
/// - Scoreboard: `data.ncaa.com/casablanca/scoreboard/lacrosse-men/d1/{yyyy}/{mm}/{dd}/scoreboard.json`
///   Returns JSON with `games` array, each containing team names, scores, game state, conferences.
///   Tested with 2025 lacrosse season dates -- returns 30+ games on active days.
///
/// - Box Score: `data.ncaa.com/casablanca/game/{gameID}/boxscore.json`
///   Returns 404 for lacrosse games tested. NOT AVAILABLE for lacrosse as of audit date.
///
/// - Game Info: `data.ncaa.com/casablanca/game/{gameID}/gameInfo.json`
///   Returns 404 for lacrosse games tested. NOT AVAILABLE.
///
/// ## Data Quality
///
/// The NCAA scoreboard provides:
/// - Team full names, short names, char6 abbreviations, SEO slugs
/// - Scores (as strings, need Int conversion)
/// - Game state: "pre", "live", "final"
/// - Current period and contest clock for live games
/// - Conference names for both teams
/// - Start time as epoch string and formatted date
/// - Win/loss records in description field (e.g., "(8-3)")
/// - Rankings (if ranked)
///
/// Missing from NCAA API:
/// - Individual player stats (no box score endpoint for lacrosse)
/// - Quarter-by-quarter scoring breakdown
/// - Detailed team stats (shots, saves, ground balls, etc.)
struct NCAAAPIScraper {
    let app: Application

    /// Maximum retry attempts for failed requests.
    private let maxRetries = 3

    /// Delay between retries in nanoseconds.
    private let retryDelay: UInt64 = 2_000_000_000 // 2 seconds

    // MARK: - Codable Structs Matching NCAA JSON Structure

    struct NCAAScoreboard: Codable {
        let games: [NCAAGameWrapper]
        let updated_at: String?  // swiftlint:disable:this identifier_name
    }

    struct NCAAGameWrapper: Codable {
        let game: NCAAGame
    }

    struct NCAAGame: Codable {
        let gameID: String
        let away: NCAATeamScore
        let home: NCAATeamScore
        let finalMessage: String?
        let bracketRound: String?
        let title: String?
        let contestName: String?
        let url: String?
        let network: String?
        let liveVideoEnabled: Bool?
        let startTime: String?
        let startTimeEpoch: String?
        let bracketId: String?
        let gameState: String       // "pre", "live", "final"
        let startDate: String?
        let currentPeriod: String?
        let videoState: String?
        let bracketRegion: String?
        let contestClock: String?
    }

    struct NCAATeamScore: Codable {
        let score: String?
        let names: NCAATeamNames
        let winner: Bool?
        let seed: String?
        let description: String?    // Record like "(8-3)"
        let rank: String?
        let conferences: [NCAAConference]?
    }

    struct NCAATeamNames: Codable {
        let char6: String
        let short: String
        let seo: String
        let full: String
    }

    struct NCAAConference: Codable {
        let conferenceName: String
        let conferenceSeo: String
    }

    // MARK: - Public API

    /// Fetches all D1 men's lacrosse games for a given date from the NCAA API.
    ///
    /// - Parameter date: The date to fetch games for
    /// - Returns: Array of scraped games with NCAA data
    func fetchScoreboard(date: Date) async -> [ScrapedGame] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        formatter.timeZone = TimeZone(identifier: "America/New_York")
        let datePath = formatter.string(from: date)

        let url = "https://data.ncaa.com/casablanca/scoreboard/lacrosse-men/d1/\(datePath)/scoreboard.json"

        guard let scoreboard = await fetchWithRetry(url: url) else {
            return []
        }

        return scoreboard.games.map { wrapper in
            let game = wrapper.game
            let homeScore = Int(game.home.score ?? "0") ?? 0
            let awayScore = Int(game.away.score ?? "0") ?? 0

            // Parse start time from epoch
            var startTime: Date? = nil
            if let epochStr = game.startTimeEpoch, let epoch = TimeInterval(epochStr) {
                startTime = Date(timeIntervalSince1970: epoch)
            }

            // Map NCAA game state to our standard
            let status: String
            switch game.gameState.lowercased() {
            case "final": status = "final"
            case "live": status = "live"
            default: status = "scheduled"
            }

            return ScrapedGame(
                homeTeamName: game.home.names.short,
                awayTeamName: game.away.names.short,
                homeScore: homeScore,
                awayScore: awayScore,
                status: status,
                period: game.currentPeriod,
                clock: game.contestClock,
                startTime: startTime,
                startTimeEpoch: game.startTimeEpoch,
                externalGameID: nil,
                conferenceID: nil,
                homeConference: game.home.conferences?.first?.conferenceName,
                awayConference: game.away.conferences?.first?.conferenceName,
                homeTeamShort: game.home.names.char6,
                awayTeamShort: game.away.names.char6,
                homeTeamFull: game.home.names.full,
                awayTeamFull: game.away.names.full,
                homeRank: game.home.rank,
                awayRank: game.away.rank,
                homeRecord: game.home.description,
                awayRecord: game.away.description
            )
        }
    }

    /// Fetches scoreboard games filtered to a specific conference.
    ///
    /// - Parameters:
    ///   - date: The date to fetch games for
    ///   - conference: Conference name to filter by (e.g., "Big Ten", "ACC")
    /// - Returns: Games where at least one team belongs to the specified conference
    func fetchScoreboard(date: Date, conference: String) async -> [ScrapedGame] {
        let allGames = await fetchScoreboard(date: date)
        let conferenceLower = conference.lowercased()

        return allGames.filter { game in
            let homeConf = game.homeConference?.lowercased() ?? ""
            let awayConf = game.awayConference?.lowercased() ?? ""
            return homeConf.contains(conferenceLower) || awayConf.contains(conferenceLower)
        }
    }

    // MARK: - Private Methods

    /// Fetches and decodes the NCAA scoreboard JSON with retry logic.
    private func fetchWithRetry(url: String) async -> NCAAScoreboard? {
        for attempt in 1...maxRetries {
            do {
                let uri = URI(string: url)
                let response = try await app.client.get(uri) { req in
                    // Set a reasonable timeout and user agent
                    req.headers.add(name: .userAgent, value: "BarDown/1.0")
                }

                // Check for rate limiting
                if response.status == .tooManyRequests {
                    app.logger.warning("NCAA API: Rate limited on attempt \(attempt)")
                    if attempt < maxRetries {
                        try await Task.sleep(nanoseconds: retryDelay * UInt64(attempt))
                    }
                    continue
                }

                guard response.status == .ok else {
                    app.logger.info("NCAA API: HTTP \(response.status) for \(url)")
                    return nil // Non-retryable (404 means no games for that date)
                }

                let scoreboard = try response.content.decode(NCAAScoreboard.self)
                app.logger.info("NCAA API: Fetched \(scoreboard.games.count) games from \(url)")
                return scoreboard

            } catch let error as DecodingError {
                app.logger.error("NCAA API: Decode error for \(url): \(error)")
                return nil // Don't retry decode errors
            } catch {
                app.logger.warning("NCAA API: Network error on attempt \(attempt) for \(url): \(error)")
                if attempt < maxRetries {
                    try? await Task.sleep(nanoseconds: retryDelay)
                }
            }
        }

        app.logger.error("NCAA API: All \(maxRetries) attempts failed for \(url)")
        return nil
    }
}
