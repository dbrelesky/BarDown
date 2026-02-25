import Fluent
import Vapor

struct GameController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let games = routes.grouped("api", "v1", "games")
        games.get("today", use: todaysGames)
        games.get("date", ":date", use: gamesByDate)
        games.get(":gameID", "boxscore", use: boxScore)
    }

    @Sendable
    func todaysGames(req: Request) async throws -> [GameResponse] {
        let conference = req.query[String.self, at: "conference"]
        let today = Self.todayBounds()
        return try await fetchGames(
            on: req.db,
            from: today.start,
            to: today.end,
            conference: conference
        )
    }

    @Sendable
    func gamesByDate(req: Request) async throws -> [GameResponse] {
        guard let dateString = req.parameters.get("date") else {
            throw Abort(.badRequest, reason: "Date parameter is required")
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "America/New_York")

        guard let date = formatter.date(from: dateString) else {
            throw Abort(.badRequest, reason: "Invalid date format. Use yyyy-MM-dd")
        }

        let bounds = Self.dateBounds(for: date)
        return try await fetchGames(
            on: req.db,
            from: bounds.start,
            to: bounds.end,
            conference: nil
        )
    }

    @Sendable
    func boxScore(req: Request) async throws -> BoxScoreResponse {
        guard let gameID = req.parameters.get("gameID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid game ID")
        }

        let query = Game.query(on: req.db)
            .filter(\.$id == gameID)
            .with(\.$homeTeam) { $0.with(\.$conference) }
            .with(\.$awayTeam) { $0.with(\.$conference) }
            .with(\.$quarterScores)
            .with(\.$gameStats)
            .with(\.$playerStats) { $0.with(\.$player) }

        guard let game = try await query.first() else {
            throw Abort(.notFound, reason: "Game not found")
        }

        return BoxScoreResponse(from: game)
    }

    // MARK: - Private Helpers

    private func fetchGames(
        on db: Database,
        from start: Date,
        to end: Date,
        conference: String?
    ) async throws -> [GameResponse] {
        var query = Game.query(on: db)
            .filter(\.$startTime >= start)
            .filter(\.$startTime < end)
            .with(\.$homeTeam) { $0.with(\.$conference) }
            .with(\.$awayTeam) { $0.with(\.$conference) }
            .with(\.$quarterScores)
            .sort(\.$startTime)

        if let conference = conference {
            let upperConf = conference.uppercased()
            query = query.join(Team.self, on: \Game.$homeTeam.$id == \Team.$id)
                .join(Conference.self, on: \Team.$conference.$id == \Conference.$id)
                .filter(Conference.self, \.$abbreviation == upperConf)
        }

        let games = try await query.all()
        return games.map { GameResponse(from: $0) }
    }

    static func todayBounds() -> (start: Date, end: Date) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/New_York")!
        let now = Date()
        let start = calendar.startOfDay(for: now)
        let end = calendar.date(byAdding: .day, value: 1, to: start)!
        return (start, end)
    }

    static func dateBounds(for date: Date) -> (start: Date, end: Date) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/New_York")!
        let start = calendar.startOfDay(for: date)
        let end = calendar.date(byAdding: .day, value: 1, to: start)!
        return (start, end)
    }
}
