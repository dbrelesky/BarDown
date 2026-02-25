import Fluent
import Vapor

final class GameStats: Model, @unchecked Sendable {
    static let schema = "game_stats"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "is_home")
    var isHome: Bool

    @Field(key: "goals")
    var goals: Int

    @Field(key: "assists")
    var assists: Int

    @Field(key: "shots")
    var shots: Int

    @OptionalField(key: "shots_on_goal")
    var shotsOnGoal: Int?

    @Field(key: "saves")
    var saves: Int

    @Field(key: "ground_balls")
    var groundBalls: Int

    @Field(key: "faceoffs_won")
    var faceoffsWon: Int

    @Field(key: "faceoffs_lost")
    var faceoffsLost: Int

    @Field(key: "turnovers")
    var turnovers: Int

    @Field(key: "penalties")
    var penalties: Int

    @OptionalField(key: "penalty_minutes")
    var penaltyMinutes: Int?

    @Parent(key: "game_id")
    var game: Game

    @Parent(key: "team_id")
    var team: Team

    init() {}

    init(
        id: UUID? = nil,
        isHome: Bool,
        goals: Int,
        assists: Int,
        shots: Int,
        shotsOnGoal: Int? = nil,
        saves: Int,
        groundBalls: Int,
        faceoffsWon: Int,
        faceoffsLost: Int,
        turnovers: Int,
        penalties: Int,
        penaltyMinutes: Int? = nil,
        gameID: UUID,
        teamID: UUID
    ) {
        self.id = id
        self.isHome = isHome
        self.goals = goals
        self.assists = assists
        self.shots = shots
        self.shotsOnGoal = shotsOnGoal
        self.saves = saves
        self.groundBalls = groundBalls
        self.faceoffsWon = faceoffsWon
        self.faceoffsLost = faceoffsLost
        self.turnovers = turnovers
        self.penalties = penalties
        self.penaltyMinutes = penaltyMinutes
        self.$game.id = gameID
        self.$team.id = teamID
    }
}
