import Fluent
import SQLKit

struct CreateGame: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("games")
            .id()
            .field("home_score", .int, .required, .sql(.default(0)))
            .field("away_score", .int, .required, .sql(.default(0)))
            .field("status", .string, .required)
            .field("period", .string)
            .field("clock", .string)
            .field("start_time", .datetime, .required)
            .field("season", .int, .required, .sql(.default(2026)))
            .field("stat_broadcast_id", .string)
            .field("ncaa_game_id", .string)
            .field("home_team_id", .uuid, .required, .references("teams", "id", onDelete: .cascade))
            .field("away_team_id", .uuid, .required, .references("teams", "id", onDelete: .cascade))
            .field("updated_at", .datetime)
            .create()

        // Create indexes for common queries
        guard let sql = database as? SQLDatabase else { return }
        try await sql.raw("CREATE INDEX idx_games_start_time ON games (start_time)").run()
        try await sql.raw("CREATE INDEX idx_games_status ON games (status)").run()
    }

    func revert(on database: Database) async throws {
        try await database.schema("games").delete()
    }
}
