import Foundation

struct TeamModel: Decodable, Identifiable {
    let id: UUID
    let name: String
    let abbreviation: String
    let conference: String
    let logoAssetName: String?
    let record: String?
    let ranking: Int?
}

extension TeamModel {
    static var placeholder: TeamModel {
        TeamModel(
            id: UUID(),
            name: "Team Name",
            abbreviation: "TM",
            conference: "Conference",
            logoAssetName: nil,
            record: "0-0",
            ranking: nil
        )
    }
}
