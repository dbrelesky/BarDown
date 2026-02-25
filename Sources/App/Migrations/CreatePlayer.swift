import Fluent

struct CreatePlayer: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("players")
            .id()
            .field("first_name", .string, .required)
            .field("last_name", .string, .required)
            .field("number", .string)
            .field("position", .string)
            .field("team_id", .uuid, .required, .references("teams", "id", onDelete: .cascade))
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("players").delete()
    }
}
