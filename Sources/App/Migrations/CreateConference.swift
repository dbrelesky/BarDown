import Fluent

struct CreateConference: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("conferences")
            .id()
            .field("name", .string, .required)
            .field("abbreviation", .string, .required)
            .field("stat_broadcast_id", .string)
            .field("ncaa_id", .string)
            .unique(on: "stat_broadcast_id")
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("conferences").delete()
    }
}
