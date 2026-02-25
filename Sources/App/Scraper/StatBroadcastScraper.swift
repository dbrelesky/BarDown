import Vapor
import SwiftSoup

/// Scrapes game data from StatBroadcast for D1 men's lacrosse.
///
/// ## Audit Findings (2026-02-24)
///
/// StatBroadcast renders scoreboards client-side via JavaScript. The `StatBroadcastScoreboard`
/// class calls `loadPage()` which fetches HTML fragments from XHR endpoints. Key findings:
///
/// - `scoreboards.php` endpoint returns 404 (deprecated or moved)
/// - Events page at `/events/` exists but game data is loaded dynamically
/// - Sport code for lacrosse: `lcgame` (confirmed from JS source)
/// - Logo URL pattern: `s3.amazonaws.com/s3.statbroadcast.com/logos/`
/// - Broadcast pages: `/broadcast/?id={gameID}&confid={conf}`
///
/// ## XHR Endpoints (UNVERIFIED - requires live game browser audit)
///
/// Based on StatBroadcast patterns for other sports, likely endpoints include:
/// - Scoreboard data: `/statbroadcast/api/scoreboard?confid={conf}&sport=lcgame&gender=M`
/// - Game detail: `/statbroadcast/api/game?id={gameID}`
/// - Alternative: `/scoreboard/load.php?confid={conf}&sport=lcgame`
///
/// These endpoints need verification during a live game by inspecting browser Network tab.
/// Until verified, NCAA API serves as the primary data source.
///
/// ## Conference IDs (best guesses, to be verified)
///
/// | Conference     | Likely confid values       |
/// |---------------|---------------------------|
/// | ACC           | acc                        |
/// | Big East      | bigeast                    |
/// | Big Ten       | bigten, b1g                |
/// | Patriot League| patriot                    |
/// | Ivy League    | ivy                        |
struct StatBroadcastScraper {
    let app: Application

    /// Known StatBroadcast conference ID guesses for Phase 1 conferences.
    /// These will be verified and updated once live endpoints are discovered.
    static let conferenceIDs: [String: [String]] = [
        "ACC": ["acc"],
        "BIGEAST": ["bigeast", "be"],
        "B1G": ["bigten", "b1g"],
        "PATRIOT": ["patriot", "pl"],
        "IVY": ["ivy"]
    ]

    /// Maximum retry attempts for failed requests.
    private let maxRetries = 3

    /// Delay between retries in seconds.
    private let retryDelay: UInt64 = 2_000_000_000 // 2 seconds in nanoseconds

    // MARK: - Scoreboard Scraping

    /// Fetches scoreboard data for a conference from StatBroadcast.
    /// Tries multiple known URL patterns until one returns parseable game data.
    ///
    /// - Parameter conferenceAbbreviation: Internal conference abbreviation (e.g., "ACC")
    /// - Returns: Array of scraped games, empty if all attempts fail
    func scrapeScoreboard(conferenceAbbreviation: String) async -> [ScrapedGame] {
        guard let confIDs = Self.conferenceIDs[conferenceAbbreviation] else {
            app.logger.warning("StatBroadcast: Unknown conference \(conferenceAbbreviation)")
            return []
        }

        for confID in confIDs {
            let urlPatterns = [
                "https://www.statbroadcast.com/events/?view=all&sport=lcgame&confid=\(confID)",
                "https://stats.statbroadcast.com/scoreboard/load.php?confid=\(confID)&sport=lcgame&gender=M",
                "https://www.statbroadcast.com/scoreboard/?confid=\(confID)&sport=lcgame&gender=M"
            ]

            for url in urlPatterns {
                let games = await fetchAndParse(url: url)
                if !games.isEmpty {
                    app.logger.info("StatBroadcast: Found \(games.count) games for \(conferenceAbbreviation) at \(url)")
                    return games
                }
            }
        }

        app.logger.info("StatBroadcast: No games found for \(conferenceAbbreviation) (all URL patterns failed)")
        return []
    }

    /// Fetches box score detail for a specific game.
    ///
    /// - Parameter gameID: StatBroadcast game ID
    /// - Parameter confID: Conference ID for the URL
    /// - Returns: Parsed box score data, or nil if unavailable
    func scrapeBoxScore(gameID: String, confID: String) async -> ScrapedBoxScore? {
        let urlPatterns = [
            "https://www.statbroadcast.com/broadcast/?id=\(gameID)&confid=\(confID)",
            "https://stats.statbroadcast.com/broadcast/?id=\(gameID)&confid=\(confID)"
        ]

        for url in urlPatterns {
            if let html = await fetchWithRetry(url: url) {
                do {
                    let boxScore = try BoxScoreParser.parse(html, homeTeam: "", awayTeam: "")
                    if !boxScore.quarterScores.isEmpty || !boxScore.playerStats.isEmpty {
                        app.logger.info("StatBroadcast: Parsed box score for game \(gameID)")
                        return boxScore
                    }
                } catch {
                    app.logger.warning("StatBroadcast: Failed to parse box score for game \(gameID): \(error)")
                }
            }
        }

        return nil
    }

    // MARK: - Private Methods

    /// Fetches a URL and parses the response as a scoreboard.
    private func fetchAndParse(url: String) async -> [ScrapedGame] {
        guard let html = await fetchWithRetry(url: url) else {
            return []
        }

        do {
            return try ScoreboardParser.parse(html)
        } catch {
            app.logger.warning("StatBroadcast: Parse error for \(url): \(error)")
            return []
        }
    }

    /// Fetches a URL with retry logic. Returns the response body as a string, or nil on failure.
    private func fetchWithRetry(url: String) async -> String? {
        for attempt in 1...maxRetries {
            do {
                let response = try await app.client.get(URI(string: url))

                // Check for rate limiting
                if response.status == .tooManyRequests {
                    app.logger.warning("StatBroadcast: Rate limited on attempt \(attempt) for \(url)")
                    if attempt < maxRetries {
                        try await Task.sleep(nanoseconds: retryDelay * UInt64(attempt))
                    }
                    continue
                }

                guard response.status == .ok else {
                    app.logger.debug("StatBroadcast: HTTP \(response.status) for \(url)")
                    return nil // Non-retryable status
                }

                guard let body = response.body,
                      let html = body.getString(at: body.readerIndex, length: body.readableBytes) else {
                    app.logger.debug("StatBroadcast: Empty body for \(url)")
                    return nil
                }

                return html

            } catch {
                app.logger.warning("StatBroadcast: Network error on attempt \(attempt) for \(url): \(error)")
                if attempt < maxRetries {
                    try? await Task.sleep(nanoseconds: retryDelay)
                }
            }
        }

        return nil
    }
}
