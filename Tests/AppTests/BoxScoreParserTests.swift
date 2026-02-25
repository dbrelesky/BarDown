@testable import App
import XCTVapor

final class BoxScoreParserTests: XCTestCase {

    // MARK: - Quarter Scores

    func testParseQuarterScores() throws {
        let html = """
        <table class="linescore">
          <tr><th>Team</th><th>Q1</th><th>Q2</th><th>Q3</th><th>Q4</th><th>Total</th></tr>
          <tr><td>Away Team</td><td>2</td><td>3</td><td>1</td><td>4</td><td>10</td></tr>
          <tr><td>Home Team</td><td>3</td><td>2</td><td>5</td><td>2</td><td>12</td></tr>
        </table>
        """

        let boxScore = try BoxScoreParser.parse(html, homeTeam: "Home Team", awayTeam: "Away Team")
        XCTAssertEqual(boxScore.quarterScores.count, 4)

        // Parser treats row1 as away, row2 as home
        XCTAssertEqual(boxScore.quarterScores[0].quarter, 1)
        XCTAssertEqual(boxScore.quarterScores[0].homeScore, 3)
        XCTAssertEqual(boxScore.quarterScores[0].awayScore, 2)

        XCTAssertEqual(boxScore.quarterScores[1].quarter, 2)
        XCTAssertEqual(boxScore.quarterScores[1].homeScore, 2)
        XCTAssertEqual(boxScore.quarterScores[1].awayScore, 3)

        XCTAssertEqual(boxScore.quarterScores[3].quarter, 4)
        XCTAssertEqual(boxScore.quarterScores[3].homeScore, 2)
        XCTAssertEqual(boxScore.quarterScores[3].awayScore, 4)
    }

    // MARK: - Player Stats

    func testParsePlayerStats() throws {
        let html = """
        <table class="player-stats">
          <tbody>
            <tr><td>#12 Smith, John</td><td>3</td><td>2</td><td>8</td><td>4</td><td>1</td><td>0</td><td>1</td></tr>
            <tr><td>Jones (#5)</td><td>1</td><td>0</td><td>3</td><td>2</td><td>0</td><td>1</td><td>0</td></tr>
            <tr><td>Total</td><td>4</td><td>2</td><td>11</td><td>6</td><td>1</td><td>1</td><td>1</td></tr>
          </tbody>
        </table>
        """

        let boxScore = try BoxScoreParser.parse(html, homeTeam: "Home", awayTeam: "Away")

        // Total row should be skipped
        XCTAssertEqual(boxScore.playerStats.count, 2)

        // First player: "#12 Smith, John" — number extracted from prefix
        let player1 = boxScore.playerStats[0]
        XCTAssertEqual(player1.number, "12")
        XCTAssertTrue(player1.playerName.contains("Smith"))
        XCTAssertEqual(player1.goals, 3)
        XCTAssertEqual(player1.assists, 2)
        XCTAssertEqual(player1.shots, 8)

        // Second player: "Jones (#5)" — number extracted from suffix
        let player2 = boxScore.playerStats[1]
        XCTAssertEqual(player2.number, "5")
        XCTAssertTrue(player2.playerName.contains("Jones"))
        XCTAssertEqual(player2.goals, 1)
        XCTAssertEqual(player2.assists, 0)
    }

    // MARK: - Team Stats

    func testParseTeamStats() throws {
        let html = """
        <table>
          <tfoot>
            <tr><td>Away</td><td>8</td><td>5</td><td>30</td><td>15</td><td>3</td><td>12</td></tr>
            <tr><td>Home</td><td>12</td><td>7</td><td>35</td><td>18</td><td>4</td><td>10</td></tr>
          </tfoot>
        </table>
        """

        let boxScore = try BoxScoreParser.parse(html, homeTeam: "Home", awayTeam: "Away")
        XCTAssertEqual(boxScore.awayTeamStats.teamName, "Away")
        XCTAssertEqual(boxScore.awayTeamStats.goals, 8)
        XCTAssertEqual(boxScore.awayTeamStats.assists, 5)
        XCTAssertEqual(boxScore.homeTeamStats.teamName, "Home")
        XCTAssertEqual(boxScore.homeTeamStats.goals, 12)
        XCTAssertEqual(boxScore.homeTeamStats.assists, 7)
    }

    // MARK: - Empty Box Score

    func testParseEmptyBoxScore() throws {
        let boxScore = try BoxScoreParser.parse("<div>No data</div>", homeTeam: "Home", awayTeam: "Away")
        XCTAssertEqual(boxScore.quarterScores.count, 0)
        XCTAssertEqual(boxScore.playerStats.count, 0)
        XCTAssertEqual(boxScore.homeTeamStats.goals, 0)
        XCTAssertEqual(boxScore.awayTeamStats.goals, 0)
    }

    func testParseCompletelyEmptyHTML() throws {
        let boxScore = try BoxScoreParser.parse("", homeTeam: "Home", awayTeam: "Away")
        XCTAssertEqual(boxScore.quarterScores.count, 0)
        XCTAssertEqual(boxScore.playerStats.count, 0)
    }

    // MARK: - Player with no number

    func testParsePlayerWithoutNumber() throws {
        let html = """
        <table class="player-stats">
          <tbody>
            <tr><td>Williams</td><td>0</td><td>1</td><td>2</td><td>1</td></tr>
          </tbody>
        </table>
        """

        let boxScore = try BoxScoreParser.parse(html, homeTeam: "Home", awayTeam: "Away")
        XCTAssertEqual(boxScore.playerStats.count, 1)
        XCTAssertEqual(boxScore.playerStats[0].playerName, "Williams")
        XCTAssertNil(boxScore.playerStats[0].number)
    }
}
