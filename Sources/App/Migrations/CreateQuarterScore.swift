import Fluent

struct CreateQuarterScore: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("quarter_scores")
            .id()
            .field("quarter", .int, .required)
            .field("home_score", .int, .required)
            .field("away_score", .int, .required)
            .field("game_id", .uuid, .required, .references("games", "id", onDelete: .cascade))
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("quarter_scores").delete()
    }
}
