import Fluent

struct CreatePlayerGameStats: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("player_game_stats")
            .id()
            .field("goals", .int, .required)
            .field("assists", .int, .required)
            .field("points", .int, .required)
            .field("shots", .int, .required)
            .field("shots_on_goal", .int)
            .field("saves", .int)
            .field("ground_balls", .int)
            .field("faceoffs_won", .int)
            .field("faceoffs_lost", .int)
            .field("turnovers", .int)
            .field("caused_turnovers", .int)
            .field("penalties", .int)
            .field("penalty_minutes", .int)
            .field("game_id", .uuid, .required, .references("games", "id", onDelete: .cascade))
            .field("player_id", .uuid, .required, .references("players", "id", onDelete: .cascade))
            .unique(on: "game_id", "player_id")
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("player_game_stats").delete()
    }
}
