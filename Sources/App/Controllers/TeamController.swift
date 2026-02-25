import Fluent
import Vapor

struct TeamController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let teams = routes.grouped("api", "v1", "teams")
        teams.get(use: allTeams)
        teams.get(":teamID", "schedule", use: teamSchedule)
    }

    @Sendable
    func allTeams(req: Request) async throws -> [String: [TeamBrief]] {
        let conferences = try await Conference.query(on: req.db)
            .with(\.$teams)
            .all()

        var result: [String: [TeamBrief]] = [:]
        for conference in conferences {
            let teamBriefs = conference.teams.map { team -> TeamBrief in
                // Manually set the conference eager-load value for TeamBrief init
                team.$conference.value = conference
                return TeamBrief(from: team)
            }
            if !teamBriefs.isEmpty {
                result[conference.abbreviation] = teamBriefs
            }
        }
        return result
    }

    @Sendable
    func teamSchedule(req: Request) async throws -> ScheduleResponse {
        guard let teamID = req.parameters.get("teamID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid team ID")
        }

        guard let team = try await Team.query(on: req.db)
            .filter(\.$id == teamID)
            .with(\.$conference)
            .first()
        else {
            throw Abort(.notFound, reason: "Team not found")
        }

        let games = try await Game.query(on: req.db)
            .group(.or) { group in
                group.filter(\.$homeTeam.$id == teamID)
                group.filter(\.$awayTeam.$id == teamID)
            }
            .filter(\.$season == 2026)
            .with(\.$homeTeam) { $0.with(\.$conference) }
            .with(\.$awayTeam) { $0.with(\.$conference) }
            .sort(\.$startTime)
            .all()

        let scheduleGames = games.map { ScheduleGameDTO(from: $0, forTeamID: teamID) }
        return ScheduleResponse(team: TeamBrief(from: team), games: scheduleGames)
    }
}
