import Vapor

struct TeamBrief: Content {
    let id: UUID
    let name: String
    let abbreviation: String
    let conference: String
    let logoAssetName: String?
    let record: String?
    let ranking: Int?

    init(from team: Team) {
        self.id = team.id!
        self.name = team.name
        self.abbreviation = team.abbreviation
        self.conference = team.$conference.value?.abbreviation ?? "Unknown"
        self.logoAssetName = team.logoAssetName
        self.record = "\(team.wins)-\(team.losses)"
        self.ranking = team.ranking
    }
}
