import Vapor
import SwiftSoup

/// Represents a parsed player stat line from a box score.
struct ScrapedPlayerStats {
    let playerName: String
    let number: String?
    let team: String
    let position: String?
    let goals: Int
    let assists: Int
    let shots: Int
    let saves: Int
    let groundBalls: Int
    let faceoffsWon: Int
    let faceoffsLost: Int
    let turnovers: Int
    let causedTurnovers: Int
    let penalties: Int
    let penaltyMinutes: Int
}

/// Represents a full box score parsed from a game detail page.
struct ScrapedBoxScore {
    let quarterScores: [(quarter: Int, homeScore: Int, awayScore: Int)]
    let homeTeamStats: ScrapedTeamStats
    let awayTeamStats: ScrapedTeamStats
    let playerStats: [ScrapedPlayerStats]
}

/// Team-level aggregate stats from a box score.
struct ScrapedTeamStats {
    let teamName: String
    let goals: Int
    let assists: Int
    let shots: Int
    let shotsOnGoal: Int?
    let saves: Int
    let groundBalls: Int
    let faceoffsWon: Int
    let faceoffsLost: Int
    let turnovers: Int
    let penalties: Int
    let penaltyMinutes: Int?
}

/// Parses StatBroadcast box score HTML into structured game detail data.
///
/// AUDIT FINDINGS (2026-02-24):
/// - StatBroadcast broadcast pages load at `/broadcast/?id={gameID}&confid={conf}`
/// - Data is loaded dynamically via JavaScript (same pattern as scoreboard)
/// - Exact HTML structure of box score data is unknown until live game audit
/// - NCAA boxscore endpoint (`/casablanca/game/{id}/boxscore.json`) returns 404 for lacrosse
///
/// This parser handles multiple potential HTML structures for box score data.
/// Selectors will be refined once StatBroadcast XHR responses are captured during live games.
struct BoxScoreParser {

    /// Parses box score HTML into structured data.
    static func parse(_ html: String, homeTeam: String, awayTeam: String) throws -> ScrapedBoxScore {
        let doc = try SwiftSoup.parse(html)

        let quarterScores = try parseQuarterScores(doc)
        let playerStats = try parsePlayerStats(doc, homeTeam: homeTeam, awayTeam: awayTeam)
        let teamStats = try parseTeamStats(doc, homeTeam: homeTeam, awayTeam: awayTeam)

        return ScrapedBoxScore(
            quarterScores: quarterScores,
            homeTeamStats: teamStats.home,
            awayTeamStats: teamStats.away,
            playerStats: playerStats
        )
    }

    // MARK: - Quarter Scores

    private static func parseQuarterScores(_ doc: Document) throws -> [(quarter: Int, homeScore: Int, awayScore: Int)] {
        var scores: [(quarter: Int, homeScore: Int, awayScore: Int)] = []

        // Look for linescore table (common StatBroadcast pattern)
        let linescoreRows = try doc.select(".linescore tr, #linescore tr, table.linescore tr")
        if linescoreRows.size() >= 2 {
            // First data row is typically away, second is home (or vice versa)
            let headerCells = try linescoreRows.first()?.select("th, td") ?? Elements()
            let row1Cells = try linescoreRows.size() > 1 ? linescoreRows.get(1).select("td") : Elements()
            let row2Cells = try linescoreRows.size() > 2 ? linescoreRows.get(2).select("td") : Elements()

            // Find quarter columns (skip team name and total columns)
            let quarterCount = max(0, headerCells.size() - 2) // subtract team name + total
            for q in 0..<quarterCount {
                let cellIndex = q + 1 // skip team name column
                guard cellIndex < row1Cells.size(), cellIndex < row2Cells.size() else { break }

                let score1 = Int(try row1Cells.get(cellIndex).text()) ?? 0
                let score2 = Int(try row2Cells.get(cellIndex).text()) ?? 0

                scores.append((quarter: q + 1, homeScore: score2, awayScore: score1))
            }
        }

        return scores
    }

    // MARK: - Player Stats

    private static func parsePlayerStats(_ doc: Document, homeTeam: String, awayTeam: String) throws -> [ScrapedPlayerStats] {
        var stats: [ScrapedPlayerStats] = []

        // Look for player stat tables
        let statTables = try doc.select("table.player-stats, table.boxscore, .stats-table table")

        for (index, table) in statTables.enumerated() {
            let team = index == 0 ? awayTeam : homeTeam // First table is typically away
            let rows = try table.select("tbody tr")

            for row in rows {
                let cells = try row.select("td")
                guard cells.size() >= 4 else { continue } // Need at minimum: name + a few stat columns

                // Skip total/summary rows
                let firstCell = try cells.first()?.text() ?? ""
                if firstCell.lowercased().contains("total") || firstCell.lowercased().contains("team") {
                    continue
                }

                let playerStat = try parsePlayerRow(cells, team: team)
                if let playerStat = playerStat {
                    stats.append(playerStat)
                }
            }
        }

        return stats
    }

    private static func parsePlayerRow(_ cells: Elements, team: String) throws -> ScrapedPlayerStats? {
        guard cells.size() >= 3 else { return nil }

        let nameCell = try cells.first()?.text() ?? ""
        guard !nameCell.isEmpty else { return nil }

        // Try to extract number from name (e.g., "#12 Smith, John" or "12 - Smith, John")
        let (name, number) = extractNumberFromName(nameCell)

        // Parse stats based on available columns
        // Standard lacrosse box score columns: G, A, Sh, SOG, GB, TO, CT, FO, Sv, Pen
        // Column order varies by source, so we try to be flexible
        let values = try cells.array().dropFirst().map { try $0.text() }
        let intValues = values.map { Int($0) ?? 0 }

        // Minimum viable stat line: goals, assists, shots
        guard intValues.count >= 3 else { return nil }

        return ScrapedPlayerStats(
            playerName: name,
            number: number,
            team: team,
            position: nil,
            goals: intValues.count > 0 ? intValues[0] : 0,
            assists: intValues.count > 1 ? intValues[1] : 0,
            shots: intValues.count > 2 ? intValues[2] : 0,
            saves: intValues.count > 6 ? intValues[6] : 0,
            groundBalls: intValues.count > 3 ? intValues[3] : 0,
            faceoffsWon: intValues.count > 7 ? intValues[7] : 0,
            faceoffsLost: intValues.count > 8 ? intValues[8] : 0,
            turnovers: intValues.count > 4 ? intValues[4] : 0,
            causedTurnovers: intValues.count > 5 ? intValues[5] : 0,
            penalties: intValues.count > 9 ? intValues[9] : 0,
            penaltyMinutes: intValues.count > 10 ? intValues[10] : 0
        )
    }

    /// Extracts jersey number from a player name string.
    /// Handles formats like "#12 Smith", "12 - Smith, John", "Smith, John (#12)"
    private static func extractNumberFromName(_ raw: String) -> (name: String, number: String?) {
        var name = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        var number: String? = nil

        // Pattern: "#12 Name" or "12 Name"
        if name.hasPrefix("#") {
            name = String(name.dropFirst())
        }

        // Try to extract leading number
        let parts = name.split(separator: " ", maxSplits: 1)
        if parts.count == 2, let _ = Int(String(parts[0])) {
            number = String(parts[0])
            name = String(parts[1])
        }

        // Pattern: "Name (#12)"
        if let range = name.range(of: #"\(#?\d+\)"#, options: .regularExpression) {
            let numStr = String(name[range]).replacingOccurrences(of: "(", with: "")
                .replacingOccurrences(of: ")", with: "")
                .replacingOccurrences(of: "#", with: "")
            number = numStr
            name = String(name[name.startIndex..<range.lowerBound])
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return (name, number)
    }

    // MARK: - Team Stats

    private static func parseTeamStats(
        _ doc: Document,
        homeTeam: String,
        awayTeam: String
    ) throws -> (home: ScrapedTeamStats, away: ScrapedTeamStats) {
        // Look for team totals rows in stat tables
        let totalRows = try doc.select("tr.totals, tr.team-totals, tfoot tr")

        let emptyStats = ScrapedTeamStats(
            teamName: "", goals: 0, assists: 0, shots: 0, shotsOnGoal: nil,
            saves: 0, groundBalls: 0, faceoffsWon: 0, faceoffsLost: 0,
            turnovers: 0, penalties: 0, penaltyMinutes: nil
        )

        var awayStats = ScrapedTeamStats(
            teamName: awayTeam, goals: 0, assists: 0, shots: 0, shotsOnGoal: nil,
            saves: 0, groundBalls: 0, faceoffsWon: 0, faceoffsLost: 0,
            turnovers: 0, penalties: 0, penaltyMinutes: nil
        )
        var homeStats = ScrapedTeamStats(
            teamName: homeTeam, goals: 0, assists: 0, shots: 0, shotsOnGoal: nil,
            saves: 0, groundBalls: 0, faceoffsWon: 0, faceoffsLost: 0,
            turnovers: 0, penalties: 0, penaltyMinutes: nil
        )

        for (index, row) in totalRows.enumerated() {
            let cells = try row.select("td")
            let values = try cells.array().dropFirst().map { Int(try $0.text()) ?? 0 }

            guard values.count >= 3 else { continue }

            let teamStats = ScrapedTeamStats(
                teamName: index == 0 ? awayTeam : homeTeam,
                goals: values.count > 0 ? values[0] : 0,
                assists: values.count > 1 ? values[1] : 0,
                shots: values.count > 2 ? values[2] : 0,
                shotsOnGoal: values.count > 3 ? values[3] : nil,
                saves: values.count > 6 ? values[6] : 0,
                groundBalls: values.count > 4 ? values[4] : 0,
                faceoffsWon: values.count > 7 ? values[7] : 0,
                faceoffsLost: values.count > 8 ? values[8] : 0,
                turnovers: values.count > 5 ? values[5] : 0,
                penalties: values.count > 9 ? values[9] : 0,
                penaltyMinutes: values.count > 10 ? values[10] : nil
            )

            if index == 0 { awayStats = teamStats }
            else { homeStats = teamStats }
        }

        // If no totals rows found, return empty stats with team names
        if totalRows.isEmpty() {
            return (
                home: ScrapedTeamStats(
                    teamName: homeTeam, goals: 0, assists: 0, shots: 0, shotsOnGoal: nil,
                    saves: 0, groundBalls: 0, faceoffsWon: 0, faceoffsLost: 0,
                    turnovers: 0, penalties: 0, penaltyMinutes: nil
                ),
                away: ScrapedTeamStats(
                    teamName: awayTeam, goals: 0, assists: 0, shots: 0, shotsOnGoal: nil,
                    saves: 0, groundBalls: 0, faceoffsWon: 0, faceoffsLost: 0,
                    turnovers: 0, penalties: 0, penaltyMinutes: nil
                )
            )
        }

        return (home: homeStats, away: awayStats)
    }
}
