import Fluent
import Vapor

final class Game: Model, @unchecked Sendable {
    static let schema = "games"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "home_score")
    var homeScore: Int

    @Field(key: "away_score")
    var awayScore: Int

    @Field(key: "status")
    var status: String

    @OptionalField(key: "period")
    var period: String?

    @OptionalField(key: "clock")
    var clock: String?

    @Field(key: "start_time")
    var startTime: Date

    @Field(key: "season")
    var season: Int

    @OptionalField(key: "stat_broadcast_id")
    var statBroadcastID: String?

    @OptionalField(key: "ncaa_game_id")
    var ncaaGameID: String?

    @Parent(key: "home_team_id")
    var homeTeam: Team

    @Parent(key: "away_team_id")
    var awayTeam: Team

    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?

    @Children(for: \.$game)
    var quarterScores: [QuarterScore]

    @Children(for: \.$game)
    var playerStats: [PlayerGameStats]

    @Children(for: \.$game)
    var gameStats: [GameStats]

    init() {}

    init(
        id: UUID? = nil,
        homeScore: Int = 0,
        awayScore: Int = 0,
        status: String = "scheduled",
        period: String? = nil,
        clock: String? = nil,
        startTime: Date,
        season: Int = 2026,
        statBroadcastID: String? = nil,
        ncaaGameID: String? = nil,
        homeTeamID: UUID,
        awayTeamID: UUID
    ) {
        self.id = id
        self.homeScore = homeScore
        self.awayScore = awayScore
        self.status = status
        self.period = period
        self.clock = clock
        self.startTime = startTime
        self.season = season
        self.statBroadcastID = statBroadcastID
        self.ncaaGameID = ncaaGameID
        self.$homeTeam.id = homeTeamID
        self.$awayTeam.id = awayTeamID
    }
}
