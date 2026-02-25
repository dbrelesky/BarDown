@testable import App
import XCTVapor

final class ScoreboardParserTests: XCTestCase {

    // MARK: - Table Format

    func testParseTableFormat() throws {
        let html = """
        <table>
          <tr class="game-row" data-game-id="12345">
            <td class="team">Syracuse</td>
            <td class="team">Duke</td>
            <td class="score">8</td>
            <td class="score">12</td>
            <td class="game-status">Final</td>
            <td class="period">4th</td>
            <td class="clock">0:00</td>
          </tr>
          <tr class="game-row" data-game-id="67890">
            <td class="team">Virginia</td>
            <td class="team">Maryland</td>
            <td class="score">5</td>
            <td class="score">3</td>
            <td class="game-status">In Progress</td>
            <td class="period">2nd</td>
            <td class="clock">7:42</td>
          </tr>
        </table>
        """

        let games = try ScoreboardParser.parse(html)
        XCTAssertEqual(games.count, 2)

        XCTAssertEqual(games[0].homeTeamName, "Syracuse")
        XCTAssertEqual(games[0].awayTeamName, "Duke")
        XCTAssertEqual(games[0].homeScore, 8)
        XCTAssertEqual(games[0].awayScore, 12)
        XCTAssertEqual(games[0].status, "final")
        XCTAssertEqual(games[0].externalGameID, "12345")

        XCTAssertEqual(games[1].homeTeamName, "Virginia")
        XCTAssertEqual(games[1].awayTeamName, "Maryland")
        XCTAssertEqual(games[1].status, "live")
    }

    // MARK: - Card Format

    func testParseCardFormat() throws {
        let html = """
        <div class="game-card" data-id="abc123">
          <div class="team">Notre Dame</div>
          <div class="team">Georgetown</div>
          <div class="score">10</div>
          <div class="score">7</div>
          <div class="status">Final</div>
        </div>
        """

        let games = try ScoreboardParser.parse(html)
        XCTAssertEqual(games.count, 1)
        XCTAssertEqual(games[0].homeTeamName, "Notre Dame")
        XCTAssertEqual(games[0].awayTeamName, "Georgetown")
        XCTAssertEqual(games[0].homeScore, 10)
        XCTAssertEqual(games[0].awayScore, 7)
        XCTAssertEqual(games[0].status, "final")
        XCTAssertEqual(games[0].externalGameID, "abc123")
    }

    // MARK: - Data Attributes Format

    func testParseDataAttributes() throws {
        let html = """
        <div data-home-score="14" data-away-score="9"
             data-home-team="Cornell" data-away-team="Yale"
             data-status="final" data-period="4th" data-clock="0:00"
             data-game-id="xyz789">
        </div>
        """

        let games = try ScoreboardParser.parse(html)
        XCTAssertEqual(games.count, 1)
        XCTAssertEqual(games[0].homeTeamName, "Cornell")
        XCTAssertEqual(games[0].awayTeamName, "Yale")
        XCTAssertEqual(games[0].homeScore, 14)
        XCTAssertEqual(games[0].awayScore, 9)
        XCTAssertEqual(games[0].status, "final")
    }

    // MARK: - Empty / Unrecognized HTML

    func testParseEmptyHTML() throws {
        let games = try ScoreboardParser.parse("<div>No games today</div>")
        XCTAssertEqual(games.count, 0)
    }

    func testParseCompletelyEmpty() throws {
        let games = try ScoreboardParser.parse("")
        XCTAssertEqual(games.count, 0)
    }

    // MARK: - normalizeStatus

    func testNormalizeStatusFinal() {
        XCTAssertEqual(ScoreboardParser.normalizeStatus("Final"), "final")
        XCTAssertEqual(ScoreboardParser.normalizeStatus("FINAL"), "final")
        XCTAssertEqual(ScoreboardParser.normalizeStatus("Final/OT"), "final")
    }

    func testNormalizeStatusLive() {
        XCTAssertEqual(ScoreboardParser.normalizeStatus("Live"), "live")
        XCTAssertEqual(ScoreboardParser.normalizeStatus("In Progress"), "live")
        XCTAssertEqual(ScoreboardParser.normalizeStatus("Halftime"), "live")
        XCTAssertEqual(ScoreboardParser.normalizeStatus("1st Quarter"), "live")
        XCTAssertEqual(ScoreboardParser.normalizeStatus("2nd"), "live")
        XCTAssertEqual(ScoreboardParser.normalizeStatus("3rd Period"), "live")
        XCTAssertEqual(ScoreboardParser.normalizeStatus("4th"), "live")
        XCTAssertEqual(ScoreboardParser.normalizeStatus("OT"), "live")
    }

    func testNormalizeStatusScheduled() {
        XCTAssertEqual(ScoreboardParser.normalizeStatus("Scheduled"), "scheduled")
        XCTAssertEqual(ScoreboardParser.normalizeStatus("Pre-Game"), "scheduled")
        XCTAssertEqual(ScoreboardParser.normalizeStatus("TBA"), "scheduled")
    }

    func testNormalizeStatusUnknown() {
        XCTAssertEqual(ScoreboardParser.normalizeStatus("something weird"), "scheduled")
    }
}
