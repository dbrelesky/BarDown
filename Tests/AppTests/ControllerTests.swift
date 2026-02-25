@testable import App
import Fluent
import FluentPostgresDriver
import XCTVapor

final class ControllerTests: XCTestCase {

    var app: Application!

    override func setUp() async throws {
        app = try await Application.make(.testing)

        // Use local test database
        let hostname = Environment.get("DATABASE_HOST") ?? "localhost"
        let port = Environment.get("DATABASE_PORT").flatMap(Int.init) ?? 5432
        let username = Environment.get("DATABASE_USERNAME") ?? "vapor"
        let password = Environment.get("DATABASE_PASSWORD") ?? "vapor"
        let database = Environment.get("TEST_DATABASE_NAME") ?? "bardown_test"

        let config = SQLPostgresConfiguration(
            hostname: hostname,
            port: port,
            username: username,
            password: password,
            database: database,
            tls: .disable
        )
        app.databases.use(.postgres(configuration: config), as: .psql)

        // Add migrations
        app.migrations.add(CreateConference())
        app.migrations.add(CreateTeam())
        app.migrations.add(CreatePlayer())
        app.migrations.add(CreateGame())
        app.migrations.add(CreateQuarterScore())
        app.migrations.add(CreateGameStats())
        app.migrations.add(CreatePlayerGameStats())

        try await app.autoMigrate()

        // Register routes WITHOUT middleware so controller logic is tested in isolation
        try routes(app)
    }

    override func tearDown() async throws {
        try await app.autoRevert()
        try await app.asyncShutdown()
    }

    // MARK: - Test Data Helpers

    private func seedTestData() async throws -> (conference: Conference, homeTeam: Team, awayTeam: Team, game: Game) {
        let conference = Conference(name: "Atlantic Coast Conference", abbreviation: "ACC")
        try await conference.save(on: app.db)

        let homeTeam = Team(
            name: "Syracuse Orange",
            abbreviation: "SYR",
            wins: 8,
            losses: 3,
            conferenceID: conference.id!
        )
        try await homeTeam.save(on: app.db)

        let awayTeam = Team(
            name: "Duke Blue Devils",
            abbreviation: "DUKE",
            wins: 10,
            losses: 1,
            conferenceID: conference.id!
        )
        try await awayTeam.save(on: app.db)

        let game = Game(
            homeScore: 12,
            awayScore: 8,
            status: "final",
            startTime: Date(),
            season: 2026,
            homeTeamID: homeTeam.id!,
            awayTeamID: awayTeam.id!
        )
        try await game.save(on: app.db)

        return (conference, homeTeam, awayTeam, game)
    }

    // MARK: - Health Endpoint

    func testHealthEndpoint() throws {
        try app.test(.GET, "health") { res in
            XCTAssertEqual(res.status, .ok)
            let body = try res.content.decode([String: String].self)
            XCTAssertEqual(body["status"], "ok")
        }
    }

    // MARK: - GameController

    func testTodaysGames() async throws {
        let data = try await seedTestData()

        try app.test(.GET, "api/v1/games/today") { res in
            XCTAssertEqual(res.status, .ok)
            let games = try res.content.decode([GameResponse].self)
            XCTAssertEqual(games.count, 1)
            XCTAssertEqual(games[0].id, data.game.id)
            XCTAssertEqual(games[0].homeScore, 12)
            XCTAssertEqual(games[0].awayScore, 8)
            XCTAssertEqual(games[0].status, "final")
            XCTAssertEqual(games[0].homeTeam.name, "Syracuse Orange")
            XCTAssertEqual(games[0].awayTeam.name, "Duke Blue Devils")
        }
    }

    func testTodaysGamesWithConferenceFilter() async throws {
        _ = try await seedTestData()

        try app.test(.GET, "api/v1/games/today?conference=ACC") { res in
            XCTAssertEqual(res.status, .ok)
            let games = try res.content.decode([GameResponse].self)
            XCTAssertEqual(games.count, 1)
        }

        try app.test(.GET, "api/v1/games/today?conference=B1G") { res in
            XCTAssertEqual(res.status, .ok)
            let games = try res.content.decode([GameResponse].self)
            XCTAssertEqual(games.count, 0)
        }
    }

    func testGamesByDate() async throws {
        _ = try await seedTestData()

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "America/New_York")
        let todayString = formatter.string(from: Date())

        try app.test(.GET, "api/v1/games/date/\(todayString)") { res in
            XCTAssertEqual(res.status, .ok)
            let games = try res.content.decode([GameResponse].self)
            XCTAssertEqual(games.count, 1)
        }
    }

    func testGamesByDateInvalidFormat() throws {
        try app.test(.GET, "api/v1/games/date/not-a-date") { res in
            XCTAssertEqual(res.status, .badRequest)
        }
    }

    func testBoxScore() async throws {
        let data = try await seedTestData()

        try app.test(.GET, "api/v1/games/\(data.game.id!)/boxscore") { res in
            XCTAssertEqual(res.status, .ok)
            let boxScore = try res.content.decode(BoxScoreResponse.self)
            XCTAssertEqual(boxScore.game.id, data.game.id)
            XCTAssertEqual(boxScore.game.homeScore, 12)
            XCTAssertEqual(boxScore.game.awayScore, 8)
        }
    }

    func testBoxScoreNotFound() throws {
        let fakeID = UUID()
        try app.test(.GET, "api/v1/games/\(fakeID)/boxscore") { res in
            XCTAssertEqual(res.status, .notFound)
        }
    }

    // MARK: - TeamController

    func testAllTeams() async throws {
        _ = try await seedTestData()

        try app.test(.GET, "api/v1/teams") { res in
            XCTAssertEqual(res.status, .ok)
            let teams = try res.content.decode([String: [TeamBrief]].self)
            XCTAssertNotNil(teams["ACC"])
            XCTAssertEqual(teams["ACC"]?.count, 2)
        }
    }

    func testTeamSchedule() async throws {
        let data = try await seedTestData()

        try app.test(.GET, "api/v1/teams/\(data.homeTeam.id!)/schedule") { res in
            XCTAssertEqual(res.status, .ok)
            let schedule = try res.content.decode(ScheduleResponse.self)
            XCTAssertEqual(schedule.team.name, "Syracuse Orange")
            XCTAssertEqual(schedule.games.count, 1)
            XCTAssertEqual(schedule.games[0].opponent.name, "Duke Blue Devils")
            XCTAssertTrue(schedule.games[0].isHome)
        }
    }

    func testTeamScheduleNotFound() throws {
        let fakeID = UUID()
        try app.test(.GET, "api/v1/teams/\(fakeID)/schedule") { res in
            XCTAssertEqual(res.status, .notFound)
        }
    }

    // MARK: - Empty State

    func testTodaysGamesEmpty() throws {
        try app.test(.GET, "api/v1/games/today") { res in
            XCTAssertEqual(res.status, .ok)
            let games = try res.content.decode([GameResponse].self)
            XCTAssertEqual(games.count, 0)
        }
    }

    func testAllTeamsEmpty() throws {
        try app.test(.GET, "api/v1/teams") { res in
            XCTAssertEqual(res.status, .ok)
            let teams = try res.content.decode([String: [TeamBrief]].self)
            XCTAssertTrue(teams.isEmpty)
        }
    }
}
