import Fluent
import Vapor

final class Conference: Model, @unchecked Sendable {
    static let schema = "conferences"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "name")
    var name: String

    @Field(key: "abbreviation")
    var abbreviation: String

    @OptionalField(key: "stat_broadcast_id")
    var statBroadcastID: String?

    @OptionalField(key: "ncaa_id")
    var ncaaID: String?

    @Children(for: \.$conference)
    var teams: [Team]

    init() {}

    init(
        id: UUID? = nil,
        name: String,
        abbreviation: String,
        statBroadcastID: String? = nil,
        ncaaID: String? = nil
    ) {
        self.id = id
        self.name = name
        self.abbreviation = abbreviation
        self.statBroadcastID = statBroadcastID
        self.ncaaID = ncaaID
    }
}
