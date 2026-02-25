import Fluent

struct CreateTeam: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("teams")
            .id()
            .field("name", .string, .required)
            .field("abbreviation", .string, .required)
            .field("mascot", .string)
            .field("logo_asset_name", .string)
            .field("wins", .int, .required, .sql(.default(0)))
            .field("losses", .int, .required, .sql(.default(0)))
            .field("ranking", .int)
            .field("stat_broadcast_id", .string)
            .field("ncaa_id", .string)
            .field("conference_id", .uuid, .required, .references("conferences", "id", onDelete: .cascade))
            .unique(on: "stat_broadcast_id")
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("teams").delete()
    }
}
