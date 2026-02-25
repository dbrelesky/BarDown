import Vapor
import SwiftSoup

/// Represents a single game scraped from a scoreboard source.
struct ScrapedGame {
    let homeTeamName: String
    let awayTeamName: String
    let homeScore: Int
    let awayScore: Int
    let status: String          // "scheduled", "live", "final"
    let period: String?
    let clock: String?
    let startTime: Date?
    let startTimeEpoch: String?
    let externalGameID: String?
    let conferenceID: String?
    let homeConference: String?
    let awayConference: String?
    let homeTeamShort: String?
    let awayTeamShort: String?
    let homeTeamFull: String?
    let awayTeamFull: String?
    let homeRank: String?
    let awayRank: String?
    let homeRecord: String?
    let awayRecord: String?
    let homeLogoURL: String?
    let awayLogoURL: String?
}

/// Parses StatBroadcast scoreboard HTML/fragments into structured game data.
///
/// AUDIT FINDINGS (2026-02-24):
/// - StatBroadcast `scoreboards.php` returns 404; the old scoreboard endpoint is gone.
/// - StatBroadcast events page (`/events/`) loads data via client-side JavaScript.
/// - XHR endpoints not discoverable without a live browser session during active games.
/// - The `StatBroadcastScoreboard` JS class calls `loadPage()` which fetches HTML fragments.
/// - Known URL pattern for broadcasts: `/broadcast/?id={gameID}&confid={conf}`
/// - Sport code for lacrosse: `lcgame`
///
/// FALLBACK: NCAA API is the primary data source until StatBroadcast XHR endpoints
/// are manually discovered during a live game session.
struct ScoreboardParser {

    /// Attempts to parse StatBroadcast scoreboard HTML fragment into game data.
    /// The expected HTML structure contains `.game-card` or similar elements
    /// with team names, scores, and game status.
    ///
    /// NOTE: Exact selectors are TBD pending manual audit of live StatBroadcast
    /// XHR responses. This parser handles known HTML fragment patterns.
    static func parse(_ html: String) throws -> [ScrapedGame] {
        let doc = try SwiftSoup.parse(html)

        // Try multiple known selector patterns
        // Pattern 1: Table-based scoreboard (common in StatBroadcast)
        let tableRows = try doc.select("tr.game-row, tr[data-game-id]")
        if !tableRows.isEmpty() {
            return try parseTableFormat(tableRows)
        }

        // Pattern 2: Card-based layout
        let gameCards = try doc.select(".game-card, .event-card, .scoreboard-game")
        if !gameCards.isEmpty() {
            return try parseCardFormat(gameCards)
        }

        // Pattern 3: Generic div-based with score data
        let scoreElements = try doc.select("[data-home-score], [data-away-score]")
        if !scoreElements.isEmpty() {
            return try parseDataAttributes(scoreElements)
        }

        // No recognizable game data found
        return []
    }

    // MARK: - Private Parsing Methods

    private static func parseTableFormat(_ rows: Elements) throws -> [ScrapedGame] {
        var games: [ScrapedGame] = []
        for row in rows {
            guard let gameID = try? row.attr("data-game-id"),
                  !gameID.isEmpty else { continue }

            let teams = try row.select(".team-name, td.team")
            guard teams.size() >= 2 else { continue }

            let scores = try row.select(".score, td.score")
            let homeScore = Int(try scores.first()?.text() ?? "0") ?? 0
            let awayScore = Int(try scores.last()?.text() ?? "0") ?? 0

            let statusEl = try row.select(".game-status, .status")
            let status = try statusEl.first()?.text().lowercased() ?? "scheduled"

            let game = ScrapedGame(
                homeTeamName: try teams.first()?.text() ?? "",
                awayTeamName: try teams.last()?.text() ?? "",
                homeScore: homeScore,
                awayScore: awayScore,
                status: normalizeStatus(status),
                period: try row.select(".period").first()?.text(),
                clock: try row.select(".clock, .time").first()?.text(),
                startTime: nil,
                startTimeEpoch: nil,
                externalGameID: gameID,
                conferenceID: nil,
                homeConference: nil,
                awayConference: nil,
                homeTeamShort: nil,
                awayTeamShort: nil,
                homeTeamFull: nil,
                awayTeamFull: nil,
                homeRank: nil,
                awayRank: nil,
                homeRecord: nil,
                awayRecord: nil,
                homeLogoURL: nil,
                awayLogoURL: nil
            )
            games.append(game)
        }
        return games
    }

    private static func parseCardFormat(_ cards: Elements) throws -> [ScrapedGame] {
        var games: [ScrapedGame] = []
        for card in cards {
            let teams = try card.select(".team-name, .team")
            guard teams.size() >= 2 else { continue }

            let scores = try card.select(".score")
            let homeScore = Int(try scores.first()?.text() ?? "0") ?? 0
            let awayScore = Int(try scores.last()?.text() ?? "0") ?? 0

            let status = try card.select(".status, .game-state").first()?.text() ?? "scheduled"

            let game = ScrapedGame(
                homeTeamName: try teams.first()?.text() ?? "",
                awayTeamName: try teams.last()?.text() ?? "",
                homeScore: homeScore,
                awayScore: awayScore,
                status: normalizeStatus(status),
                period: try card.select(".period").first()?.text(),
                clock: try card.select(".clock").first()?.text(),
                startTime: nil,
                startTimeEpoch: nil,
                externalGameID: try card.attr("data-id"),
                conferenceID: nil,
                homeConference: nil,
                awayConference: nil,
                homeTeamShort: nil,
                awayTeamShort: nil,
                homeTeamFull: nil,
                awayTeamFull: nil,
                homeRank: nil,
                awayRank: nil,
                homeRecord: nil,
                awayRecord: nil,
                homeLogoURL: nil,
                awayLogoURL: nil
            )
            games.append(game)
        }
        return games
    }

    private static func parseDataAttributes(_ elements: Elements) throws -> [ScrapedGame] {
        var games: [ScrapedGame] = []
        for element in elements {
            let homeScore = Int(try element.attr("data-home-score")) ?? 0
            let awayScore = Int(try element.attr("data-away-score")) ?? 0
            let homeName = try element.attr("data-home-team")
            let awayName = try element.attr("data-away-team")

            guard !homeName.isEmpty, !awayName.isEmpty else { continue }

            let game = ScrapedGame(
                homeTeamName: homeName,
                awayTeamName: awayName,
                homeScore: homeScore,
                awayScore: awayScore,
                status: try element.attr("data-status"),
                period: try element.attr("data-period"),
                clock: try element.attr("data-clock"),
                startTime: nil,
                startTimeEpoch: nil,
                externalGameID: try element.attr("data-game-id"),
                conferenceID: nil,
                homeConference: nil,
                awayConference: nil,
                homeTeamShort: nil,
                awayTeamShort: nil,
                homeTeamFull: nil,
                awayTeamFull: nil,
                homeRank: nil,
                awayRank: nil,
                homeRecord: nil,
                awayRecord: nil,
                homeLogoURL: nil,
                awayLogoURL: nil
            )
            games.append(game)
        }
        return games
    }

    /// Normalizes various status strings to our standard: "scheduled", "live", "final"
    static func normalizeStatus(_ raw: String) -> String {
        let lower = raw.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        if lower.contains("final") { return "final" }
        if lower.contains("live") || lower.contains("progress") || lower.contains("half") { return "live" }
        if lower.contains("pre") || lower.contains("scheduled") || lower.contains("tba") { return "scheduled" }
        // If it looks like a period indicator (e.g., "1st", "2nd", "3rd", "4th", "OT")
        if lower.contains("1st") || lower.contains("2nd") || lower.contains("3rd") ||
           lower.contains("4th") || lower.contains("ot") {
            return "live"
        }
        return "scheduled"
    }
}
