import Fluent
import Vapor

final class Team: Model, @unchecked Sendable {
    static let schema = "teams"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "name")
    var name: String

    @Field(key: "abbreviation")
    var abbreviation: String

    @OptionalField(key: "mascot")
    var mascot: String?

    @OptionalField(key: "logo_asset_name")
    var logoAssetName: String?

    @Field(key: "wins")
    var wins: Int

    @Field(key: "losses")
    var losses: Int

    @OptionalField(key: "ranking")
    var ranking: Int?

    @OptionalField(key: "stat_broadcast_id")
    var statBroadcastID: String?

    @OptionalField(key: "ncaa_id")
    var ncaaID: String?

    @Parent(key: "conference_id")
    var conference: Conference

    @Children(for: \.$team)
    var players: [Player]

    @Children(for: \.$homeTeam)
    var homeGames: [Game]

    @Children(for: \.$awayTeam)
    var awayGames: [Game]

    init() {}

    init(
        id: UUID? = nil,
        name: String,
        abbreviation: String,
        mascot: String? = nil,
        logoAssetName: String? = nil,
        wins: Int = 0,
        losses: Int = 0,
        ranking: Int? = nil,
        statBroadcastID: String? = nil,
        ncaaID: String? = nil,
        conferenceID: UUID
    ) {
        self.id = id
        self.name = name
        self.abbreviation = abbreviation
        self.mascot = mascot
        self.logoAssetName = logoAssetName
        self.wins = wins
        self.losses = losses
        self.ranking = ranking
        self.statBroadcastID = statBroadcastID
        self.ncaaID = ncaaID
        self.$conference.id = conferenceID
    }
}
