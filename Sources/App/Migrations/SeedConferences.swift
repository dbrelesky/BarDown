import Fluent

struct SeedConferences: AsyncMigration {
    func prepare(on database: Database) async throws {
        let conferences: [(name: String, abbreviation: String)] = [
            ("Big East", "BIGEAST"),
            ("ACC", "ACC"),
            ("Big Ten", "B1G"),
            ("Patriot League", "PATRIOT"),
            ("Ivy League", "IVY"),
        ]

        for conf in conferences {
            let conference = Conference(
                name: conf.name,
                abbreviation: conf.abbreviation,
                statBroadcastID: nil,
                ncaaID: nil
            )
            try await conference.save(on: database)
        }
    }

    func revert(on database: Database) async throws {
        try await Conference.query(on: database)
            .filter(\.$abbreviation ~~ ["BIGEAST", "ACC", "B1G", "PATRIOT", "IVY"])
            .delete()
    }
}
