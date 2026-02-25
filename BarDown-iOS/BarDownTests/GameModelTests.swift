import Testing
import Foundation
@testable import BarDown

// RED PHASE: GameModel and TeamModel do not exist yet.
// These tests will fail to compile until Plan 03-03 creates those types.
// Compile errors ARE the failing tests.

@Suite("GameModel JSON Decoding")
struct GameModelTests {

    // Load the fixture once and decode into [GameModel]
    private func loadFixture() throws -> [GameModel] {
        let url = Bundle(for: GameModelTestsHelper.self).url(
            forResource: "games-response",
            withExtension: "json"
        )!
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([GameModel].self, from: data)
    }

    @Test("Fixture JSON decodes into [GameModel] without throwing")
    func fixtureDecodes() throws {
        let games = try loadFixture()
        #expect(games.count == 3)
    }

    @Test("Decoded array contains 3 games")
    func gameCount() throws {
        let games = try loadFixture()
        #expect(games.count == 3)
    }

    @Test("Live game has correct status and score fields")
    func liveGameFields() throws {
        let games = try loadFixture()
        let live = try #require(games.first { $0.status == "live" })
        #expect(live.homeScore >= 0)
        #expect(live.awayScore >= 0)
        #expect(live.period != nil)
        #expect(live.clock != nil)
    }

    @Test("Scheduled game has future startTime")
    func scheduledGameStartTime() throws {
        let games = try loadFixture()
        let scheduled = try #require(games.first { $0.status == "scheduled" })
        // startTime must be a valid Date (non-nil after decoding)
        // Future check is relative to fixture date (2026-03-15)
        #expect(scheduled.startTime > Date(timeIntervalSince1970: 0))
    }

    @Test("Final game isFinal is true")
    func finalGameIsFinal() throws {
        let games = try loadFixture()
        let final_ = try #require(games.first { $0.status == "final" })
        #expect(final_.isFinal == true)
    }

    @Test("TeamModel fields are present on home and away teams")
    func teamModelFields() throws {
        let games = try loadFixture()
        let game = try #require(games.first)
        let home = game.homeTeam
        let away = game.awayTeam
        // Required fields
        #expect(!home.id.uuidString.isEmpty)
        #expect(!home.name.isEmpty)
        #expect(!home.abbreviation.isEmpty)
        #expect(!home.conference.isEmpty)
        // record is a formatted string e.g. "5-2"
        #expect(home.record != nil)
        // ranking is optional
        _ = home.ranking  // just accessing it should compile

        #expect(!away.id.uuidString.isEmpty)
        #expect(!away.name.isEmpty)
    }

    @Test("GameStatus sorts live < scheduled < final")
    func gameStatusSortOrder() throws {
        let games = try loadFixture()
        let sorted = games.sorted { $0.gameStatus < $1.gameStatus }
        #expect(sorted[0].status == "live")
        #expect(sorted[1].status == "scheduled")
        #expect(sorted[2].status == "final")
    }
}

// Objective-C class needed for Bundle(for:) fixture loading in Swift Testing
// (Swift Testing test structs are value types; Bundle(for:) requires a class)
final class GameModelTestsHelper: NSObject {}
