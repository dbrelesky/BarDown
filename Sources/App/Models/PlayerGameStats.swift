import Fluent
import Vapor

final class PlayerGameStats: Model, @unchecked Sendable {
    static let schema = "player_game_stats"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "goals")
    var goals: Int

    @Field(key: "assists")
    var assists: Int

    @Field(key: "points")
    var points: Int

    @Field(key: "shots")
    var shots: Int

    @OptionalField(key: "shots_on_goal")
    var shotsOnGoal: Int?

    @OptionalField(key: "saves")
    var saves: Int?

    @OptionalField(key: "ground_balls")
    var groundBalls: Int?

    @OptionalField(key: "faceoffs_won")
    var faceoffsWon: Int?

    @OptionalField(key: "faceoffs_lost")
    var faceoffsLost: Int?

    @OptionalField(key: "turnovers")
    var turnovers: Int?

    @OptionalField(key: "caused_turnovers")
    var causedTurnovers: Int?

    @OptionalField(key: "penalties")
    var penalties: Int?

    @OptionalField(key: "penalty_minutes")
    var penaltyMinutes: Int?

    @Parent(key: "game_id")
    var game: Game

    @Parent(key: "player_id")
    var player: Player

    init() {}

    init(
        id: UUID? = nil,
        goals: Int,
        assists: Int,
        points: Int,
        shots: Int,
        shotsOnGoal: Int? = nil,
        saves: Int? = nil,
        groundBalls: Int? = nil,
        faceoffsWon: Int? = nil,
        faceoffsLost: Int? = nil,
        turnovers: Int? = nil,
        causedTurnovers: Int? = nil,
        penalties: Int? = nil,
        penaltyMinutes: Int? = nil,
        gameID: UUID,
        playerID: UUID
    ) {
        self.id = id
        self.goals = goals
        self.assists = assists
        self.points = points
        self.shots = shots
        self.shotsOnGoal = shotsOnGoal
        self.saves = saves
        self.groundBalls = groundBalls
        self.faceoffsWon = faceoffsWon
        self.faceoffsLost = faceoffsLost
        self.turnovers = turnovers
        self.causedTurnovers = causedTurnovers
        self.penalties = penalties
        self.penaltyMinutes = penaltyMinutes
        self.$game.id = gameID
        self.$player.id = playerID
    }
}
