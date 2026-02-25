import Fluent
import Vapor

final class QuarterScore: Model, @unchecked Sendable {
    static let schema = "quarter_scores"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "quarter")
    var quarter: Int

    @Field(key: "home_score")
    var homeScore: Int

    @Field(key: "away_score")
    var awayScore: Int

    @Parent(key: "game_id")
    var game: Game

    init() {}

    init(
        id: UUID? = nil,
        quarter: Int,
        homeScore: Int,
        awayScore: Int,
        gameID: UUID
    ) {
        self.id = id
        self.quarter = quarter
        self.homeScore = homeScore
        self.awayScore = awayScore
        self.$game.id = gameID
    }
}
