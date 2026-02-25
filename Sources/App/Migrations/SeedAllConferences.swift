import Fluent

/// Adds all D1 lacrosse conferences beyond the Phase 1 seed.
struct SeedAllConferences: AsyncMigration {
    func prepare(on database: Database) async throws {
        let conferences: [(name: String, abbreviation: String)] = [
            ("CAA", "CAA"),
            ("MAAC", "MAAC"),
            ("Atlantic 10", "A10"),
            ("America East", "AE"),
            ("NEC", "NEC"),
            ("Southern Conference", "SOCON"),
            ("ASUN", "ASUN"),
            ("Big South", "BIGSOUTH"),
            ("Ohio Valley", "OVC"),
        ]

        for conf in conferences {
            // Skip if already exists (idempotent)
            let exists = try await Conference.query(on: database)
                .filter(\.$abbreviation == conf.abbreviation)
                .first()
            guard exists == nil else { continue }

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
        let abbrevs = ["CAA", "MAAC", "A10", "AE", "NEC", "SOCON", "ASUN", "BIGSOUTH", "OVC"]
        try await Conference.query(on: database)
            .filter(\.$abbreviation ~~ abbrevs)
            .delete()
    }
}
