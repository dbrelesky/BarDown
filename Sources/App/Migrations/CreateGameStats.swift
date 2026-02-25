import Fluent

struct CreateGameStats: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("game_stats")
            .id()
            .field("is_home", .bool, .required)
            .field("goals", .int, .required)
            .field("assists", .int, .required)
            .field("shots", .int, .required)
            .field("shots_on_goal", .int)
            .field("saves", .int, .required)
            .field("ground_balls", .int, .required)
            .field("faceoffs_won", .int, .required)
            .field("faceoffs_lost", .int, .required)
            .field("turnovers", .int, .required)
            .field("penalties", .int, .required)
            .field("penalty_minutes", .int)
            .field("game_id", .uuid, .required, .references("games", "id", onDelete: .cascade))
            .field("team_id", .uuid, .required, .references("teams", "id", onDelete: .cascade))
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("game_stats").delete()
    }
}
