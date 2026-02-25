import Fluent
import Vapor

final class Player: Model, @unchecked Sendable {
    static let schema = "players"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "first_name")
    var firstName: String

    @Field(key: "last_name")
    var lastName: String

    @OptionalField(key: "number")
    var number: String?

    @OptionalField(key: "position")
    var position: String?

    @Parent(key: "team_id")
    var team: Team

    init() {}

    init(
        id: UUID? = nil,
        firstName: String,
        lastName: String,
        number: String? = nil,
        position: String? = nil,
        teamID: UUID
    ) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.number = number
        self.position = position
        self.$team.id = teamID
    }
}
