import Vapor
import Fluent

/// Handles upserting scraped game data into PostgreSQL.
///
/// The reconciler matches scraped games to existing database records,
/// creates new records for unseen games, and updates existing ones.
/// Teams are auto-created when first encountered (not pre-seeded).
struct DataReconciler {
    let app: Application

    // MARK: - Conference Name Mapping

    /// Maps NCAA conference names to our internal abbreviations.
    /// Used to find the correct Conference record when creating teams.
    static let conferenceNameMap: [String: String] = [
        "acc": "ACC",
        "big east": "BIGEAST",
        "big ten": "B1G",
        "patriot": "PATRIOT",
        "ivy league": "IVY",
        "ivy": "IVY",
        // Additional conferences
        "caa": "CAA",
        "colonial": "CAA",
        "maac": "MAAC",
        "atlantic 10": "A10",
        "a-10": "A10",
        "america east": "AE",
        "nec": "NEC",
        "northeast": "NEC",
        "southern": "SOCON",
        "asun": "ASUN",
        "atlantic sun": "ASUN"
    ]

    // MARK: - Game Reconciliation

    /// Reconciles scraped games into the database.
    /// Creates or updates Game, Team records as needed.
    ///
    /// - Parameters:
    ///   - scraped: Array of scraped game data
    ///   - db: Database connection
    /// - Returns: Count of games created and updated
    @discardableResult
    func reconcileGames(scraped: [ScrapedGame], on db: Database) async throws -> (created: Int, updated: Int) {
        var created = 0
        var updated = 0

        for scrapedGame in scraped {
            do {
                // Resolve home and away teams (create if needed)
                let homeTeam = try await resolveTeam(
                    name: scrapedGame.homeTeamName,
                    fullName: scrapedGame.homeTeamFull,
                    shortName: scrapedGame.homeTeamShort,
                    conference: scrapedGame.homeConference,
                    rank: scrapedGame.homeRank,
                    record: scrapedGame.homeRecord,
                    logoURL: scrapedGame.homeLogoURL,
                    on: db
                )
                let awayTeam = try await resolveTeam(
                    name: scrapedGame.awayTeamName,
                    fullName: scrapedGame.awayTeamFull,
                    shortName: scrapedGame.awayTeamShort,
                    conference: scrapedGame.awayConference,
                    rank: scrapedGame.awayRank,
                    record: scrapedGame.awayRecord,
                    logoURL: scrapedGame.awayLogoURL,
                    on: db
                )

                guard let homeTeamID = homeTeam.id, let awayTeamID = awayTeam.id else {
                    app.logger.error("Reconciler: Missing team IDs for game \(scrapedGame.homeTeamName) vs \(scrapedGame.awayTeamName)")
                    continue
                }

                // Try to find existing game
                let existingGame = try await findExistingGame(
                    scraped: scrapedGame,
                    homeTeamID: homeTeamID,
                    awayTeamID: awayTeamID,
                    on: db
                )

                if let game = existingGame {
                    // Update existing game
                    try await updateGame(game, with: scrapedGame, on: db)
                    updated += 1
                } else {
                    // Create new game
                    try await createGame(scrapedGame, homeTeamID: homeTeamID, awayTeamID: awayTeamID, on: db)
                    created += 1
                }
            } catch {
                app.logger.error("Reconciler: Failed to reconcile game \(scrapedGame.homeTeamName) vs \(scrapedGame.awayTeamName): \(error)")
            }
        }

        app.logger.info("Reconciler: \(created) games created, \(updated) games updated out of \(scraped.count) scraped")
        return (created: created, updated: updated)
    }

    /// Reconciles box score data for a specific game.
    ///
    /// - Parameters:
    ///   - boxScore: Parsed box score data
    ///   - gameID: The game's database ID
    ///   - homeTeamID: Home team database ID
    ///   - awayTeamID: Away team database ID
    ///   - db: Database connection
    func reconcileBoxScore(
        _ boxScore: ScrapedBoxScore,
        gameID: UUID,
        homeTeamID: UUID,
        awayTeamID: UUID,
        on db: Database
    ) async throws {
        // Upsert quarter scores
        for qs in boxScore.quarterScores {
            try await upsertQuarterScore(
                gameID: gameID,
                quarter: qs.quarter,
                homeScore: qs.homeScore,
                awayScore: qs.awayScore,
                on: db
            )
        }

        // Upsert team-level game stats
        try await upsertGameStats(boxScore.homeTeamStats, gameID: gameID, teamID: homeTeamID, isHome: true, on: db)
        try await upsertGameStats(boxScore.awayTeamStats, gameID: gameID, teamID: awayTeamID, isHome: false, on: db)

        // Upsert player stats
        for playerStat in boxScore.playerStats {
            let teamID = playerStat.team == boxScore.homeTeamStats.teamName ? homeTeamID : awayTeamID
            try await upsertPlayerGameStats(playerStat, gameID: gameID, teamID: teamID, on: db)
        }
    }

    // MARK: - Team Resolution

    /// Finds or creates a team by name.
    /// Matching priority: statBroadcastID > exact name match > fuzzy name match > create new.
    private func resolveTeam(
        name: String,
        fullName: String?,
        shortName: String?,
        conference: String?,
        rank: String?,
        record: String?,
        logoURL: String? = nil,
        on db: Database
    ) async throws -> Team {
        // Try exact name match first
        let byName: Team?
        if let fullName = fullName {
            byName = try await Team.query(on: db)
                .group(.or) { group in
                    group.filter(\.$name == name)
                    group.filter(\.$name == fullName)
                }
                .first()
        } else {
            byName = try await Team.query(on: db)
                .filter(\.$name == name)
                .first()
        }
        if let existing = byName {
            try await updateTeamMetadata(existing, rank: rank, record: record, logoURL: logoURL, on: db)
            return existing
        }

        // Try abbreviation match
        if let shortName = shortName,
           let existing = try await Team.query(on: db)
            .filter(\.$abbreviation == shortName)
            .first()
        {
            try await updateTeamMetadata(existing, rank: rank, record: record, logoURL: logoURL, on: db)
            return existing
        }

        // Create new team
        let conferenceRecord = try await resolveConference(name: conference, on: db)
        guard let conferenceID = conferenceRecord.id else {
            throw ScraperError.parseError("Could not resolve conference for team \(name)")
        }

        let abbreviation = shortName ?? String(name.prefix(6)).uppercased()
        let team = Team(
            name: fullName ?? name,
            abbreviation: abbreviation,
            conferenceID: conferenceID
        )

        // Update ranking if available
        if let rankStr = rank, !rankStr.isEmpty, let rankInt = Int(rankStr) {
            team.ranking = rankInt
        }

        // Parse record if available (e.g., "(8-3)")
        if let record = record {
            let parsed = parseRecord(record)
            team.wins = parsed.wins
            team.losses = parsed.losses
        }

        // Set logo URL if provided
        if let logoURL = logoURL {
            team.logoAssetName = logoURL
        }

        try await team.save(on: db)
        app.logger.info("Reconciler: Created new team '\(team.name)' in conference \(conferenceRecord.abbreviation)")
        return team
    }

    /// Updates team ranking and record if new data is available.
    private func updateTeamMetadata(_ team: Team, rank: String?, record: String?, logoURL: String? = nil, on db: Database) async throws {
        var changed = false

        if let rankStr = rank, !rankStr.isEmpty, let rankInt = Int(rankStr) {
            if team.ranking != rankInt {
                team.ranking = rankInt
                changed = true
            }
        }

        if let record = record {
            let parsed = parseRecord(record)
            if team.wins != parsed.wins || team.losses != parsed.losses {
                team.wins = parsed.wins
                team.losses = parsed.losses
                changed = true
            }
        }

        if let logoURL = logoURL, team.logoAssetName == nil {
            team.logoAssetName = logoURL
            changed = true
        }

        if changed {
            try await team.save(on: db)
        }
    }

    /// Parses a record string like "(8-3)" into wins and losses.
    private func parseRecord(_ record: String) -> (wins: Int, losses: Int) {
        let cleaned = record.replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let parts = cleaned.split(separator: "-")
        guard parts.count >= 2,
              let wins = Int(parts[0]),
              let losses = Int(parts[1]) else {
            return (wins: 0, losses: 0)
        }
        return (wins: wins, losses: losses)
    }

    /// Finds or returns the appropriate conference for a team.
    private func resolveConference(name: String?, on db: Database) async throws -> Conference {
        if let name = name {
            let nameLower = name.lowercased()

            // Try abbreviation mapping first
            let abbrev = Self.conferenceNameMap[nameLower]
            if let abbrev = abbrev {
                let byAbbrev = try await Conference.query(on: db)
                    .filter(\.$abbreviation == abbrev)
                    .first()
                if let found = byAbbrev {
                    return found
                }
            }

            // Try direct name match
            let byName = try await Conference.query(on: db)
                .filter(\.$name == name)
                .first()
            if let found = byName {
                return found
            }

            // Try partial match on name
            let allConferences = try await Conference.query(on: db).all()
            let partialMatch = allConferences.first(where: { conf in
                conf.name.lowercased().contains(nameLower) ||
                nameLower.contains(conf.name.lowercased())
            })
            if let found = partialMatch {
                return found
            }
        }

        // Fallback: return first conference (should not happen with full conference seed)
        if let fallback = try await Conference.query(on: db).first() {
            app.logger.warning("Reconciler: Could not match conference '\(name ?? "nil")', using fallback: \(fallback.name)")
            return fallback
        }

        throw ScraperError.parseError("No conferences found in database")
    }

    // MARK: - Game CRUD

    /// Finds an existing game matching the scraped data.
    private func findExistingGame(
        scraped: ScrapedGame,
        homeTeamID: UUID,
        awayTeamID: UUID,
        on db: Database
    ) async throws -> Game? {
        // Match by NCAA game ID if available
        if let ncaaID = scraped.externalGameID, !ncaaID.isEmpty {
            if let game = try await Game.query(on: db)
                .filter(\.$ncaaGameID == ncaaID)
                .first()
            {
                return game
            }
        }

        // Match by StatBroadcast ID
        if let sbID = scraped.externalGameID, !sbID.isEmpty {
            if let game = try await Game.query(on: db)
                .filter(\.$statBroadcastID == sbID)
                .first()
            {
                return game
            }
        }

        // Match by teams + date (same day)
        if let startTime = scraped.startTime {
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: startTime)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

            return try await Game.query(on: db)
                .filter(\.$homeTeam.$id == homeTeamID)
                .filter(\.$awayTeam.$id == awayTeamID)
                .filter(\.$startTime >= startOfDay)
                .filter(\.$startTime < endOfDay)
                .first()
        }

        return nil
    }

    /// Creates a new Game record from scraped data.
    private func createGame(
        _ scraped: ScrapedGame,
        homeTeamID: UUID,
        awayTeamID: UUID,
        on db: Database
    ) async throws {
        let startTime = scraped.startTime ?? Date()

        let game = Game(
            homeScore: scraped.homeScore,
            awayScore: scraped.awayScore,
            status: scraped.status,
            period: scraped.period,
            clock: scraped.clock,
            startTime: startTime,
            season: Calendar.current.component(.year, from: startTime),
            statBroadcastID: nil,
            ncaaGameID: scraped.externalGameID,
            homeTeamID: homeTeamID,
            awayTeamID: awayTeamID
        )

        try await game.save(on: db)
    }

    /// Updates an existing Game record with new scraped data.
    private func updateGame(_ game: Game, with scraped: ScrapedGame, on db: Database) async throws {
        game.homeScore = scraped.homeScore
        game.awayScore = scraped.awayScore
        game.status = scraped.status
        game.period = scraped.period
        game.clock = scraped.clock

        // Update NCAA game ID if we didn't have it
        if game.ncaaGameID == nil, let ncaaID = scraped.externalGameID {
            game.ncaaGameID = ncaaID
        }

        try await game.save(on: db)
    }

    // MARK: - Box Score CRUD

    /// Upserts a quarter score record.
    private func upsertQuarterScore(
        gameID: UUID,
        quarter: Int,
        homeScore: Int,
        awayScore: Int,
        on db: Database
    ) async throws {
        if let existing = try await QuarterScore.query(on: db)
            .filter(\.$game.$id == gameID)
            .filter(\.$quarter == quarter)
            .first()
        {
            existing.homeScore = homeScore
            existing.awayScore = awayScore
            try await existing.save(on: db)
        } else {
            let qs = QuarterScore(
                quarter: quarter,
                homeScore: homeScore,
                awayScore: awayScore,
                gameID: gameID
            )
            try await qs.save(on: db)
        }
    }

    /// Upserts team-level game stats.
    private func upsertGameStats(
        _ stats: ScrapedTeamStats,
        gameID: UUID,
        teamID: UUID,
        isHome: Bool,
        on db: Database
    ) async throws {
        if let existing = try await GameStats.query(on: db)
            .filter(\.$game.$id == gameID)
            .filter(\.$team.$id == teamID)
            .first()
        {
            existing.goals = stats.goals
            existing.assists = stats.assists
            existing.shots = stats.shots
            existing.shotsOnGoal = stats.shotsOnGoal
            existing.saves = stats.saves
            existing.groundBalls = stats.groundBalls
            existing.faceoffsWon = stats.faceoffsWon
            existing.faceoffsLost = stats.faceoffsLost
            existing.turnovers = stats.turnovers
            existing.penalties = stats.penalties
            existing.penaltyMinutes = stats.penaltyMinutes
            try await existing.save(on: db)
        } else {
            let gs = GameStats(
                isHome: isHome,
                goals: stats.goals,
                assists: stats.assists,
                shots: stats.shots,
                shotsOnGoal: stats.shotsOnGoal,
                saves: stats.saves,
                groundBalls: stats.groundBalls,
                faceoffsWon: stats.faceoffsWon,
                faceoffsLost: stats.faceoffsLost,
                turnovers: stats.turnovers,
                penalties: stats.penalties,
                penaltyMinutes: stats.penaltyMinutes,
                gameID: gameID,
                teamID: teamID
            )
            try await gs.save(on: db)
        }
    }

    /// Upserts individual player game stats.
    private func upsertPlayerGameStats(
        _ stats: ScrapedPlayerStats,
        gameID: UUID,
        teamID: UUID,
        on db: Database
    ) async throws {
        // Resolve player (find or create)
        let player = try await resolvePlayer(stats: stats, teamID: teamID, on: db)
        guard let playerID = player.id else { return }

        if let existing = try await PlayerGameStats.query(on: db)
            .filter(\.$game.$id == gameID)
            .filter(\.$player.$id == playerID)
            .first()
        {
            existing.goals = stats.goals
            existing.assists = stats.assists
            existing.points = stats.goals + stats.assists
            existing.shots = stats.shots
            existing.saves = stats.saves > 0 ? stats.saves : nil
            existing.groundBalls = stats.groundBalls > 0 ? stats.groundBalls : nil
            existing.faceoffsWon = stats.faceoffsWon > 0 ? stats.faceoffsWon : nil
            existing.faceoffsLost = stats.faceoffsLost > 0 ? stats.faceoffsLost : nil
            existing.turnovers = stats.turnovers > 0 ? stats.turnovers : nil
            existing.causedTurnovers = stats.causedTurnovers > 0 ? stats.causedTurnovers : nil
            existing.penalties = stats.penalties > 0 ? stats.penalties : nil
            existing.penaltyMinutes = stats.penaltyMinutes > 0 ? stats.penaltyMinutes : nil
            try await existing.save(on: db)
        } else {
            let pgs = PlayerGameStats(
                goals: stats.goals,
                assists: stats.assists,
                points: stats.goals + stats.assists,
                shots: stats.shots,
                saves: stats.saves > 0 ? stats.saves : nil,
                groundBalls: stats.groundBalls > 0 ? stats.groundBalls : nil,
                faceoffsWon: stats.faceoffsWon > 0 ? stats.faceoffsWon : nil,
                faceoffsLost: stats.faceoffsLost > 0 ? stats.faceoffsLost : nil,
                turnovers: stats.turnovers > 0 ? stats.turnovers : nil,
                causedTurnovers: stats.causedTurnovers > 0 ? stats.causedTurnovers : nil,
                penalties: stats.penalties > 0 ? stats.penalties : nil,
                penaltyMinutes: stats.penaltyMinutes > 0 ? stats.penaltyMinutes : nil,
                gameID: gameID,
                playerID: playerID
            )
            try await pgs.save(on: db)
        }
    }

    /// Finds or creates a player by name and team.
    private func resolvePlayer(stats: ScrapedPlayerStats, teamID: UUID, on db: Database) async throws -> Player {
        // Parse name (handle "Last, First" or "First Last")
        let (firstName, lastName) = parseName(stats.playerName)

        // Try to find existing player on the same team
        if let existing = try await Player.query(on: db)
            .filter(\.$team.$id == teamID)
            .filter(\.$lastName == lastName)
            .filter(\.$firstName == firstName)
            .first()
        {
            // Update number if we have it and they don't
            if existing.number == nil, let number = stats.number {
                existing.number = number
                try await existing.save(on: db)
            }
            return existing
        }

        // Create new player
        let player = Player(
            firstName: firstName,
            lastName: lastName,
            number: stats.number,
            position: stats.position,
            teamID: teamID
        )
        try await player.save(on: db)
        return player
    }

    /// Parses a player name into first and last name components.
    /// Handles: "Last, First", "First Last", "Last"
    private func parseName(_ raw: String) -> (firstName: String, lastName: String) {
        let name = raw.trimmingCharacters(in: .whitespacesAndNewlines)

        // "Last, First" format
        if name.contains(",") {
            let parts = name.split(separator: ",", maxSplits: 1)
            let lastName = parts[0].trimmingCharacters(in: .whitespaces)
            let firstName = parts.count > 1 ? parts[1].trimmingCharacters(in: .whitespaces) : ""
            return (firstName, lastName)
        }

        // "First Last" format
        let parts = name.split(separator: " ", maxSplits: 1)
        if parts.count >= 2 {
            return (String(parts[0]), String(parts[1]))
        }

        // Single name
        return ("", name)
    }
}
