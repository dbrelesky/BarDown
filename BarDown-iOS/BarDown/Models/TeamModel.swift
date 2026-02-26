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
    var normalizedLogoAssetName: String? {
        guard let logoAssetName else { return nil }
        let normalized = logoAssetName.trimmingCharacters(in: .whitespacesAndNewlines)
        return normalized.isEmpty ? nil : normalized
    }

    var logoFallbackText: String {
        let trimmedAbbreviation = abbreviation.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedAbbreviation.isEmpty {
            return trimmedAbbreviation
        }

        let words = name
            .split(separator: " ")
            .map(String.init)
            .filter { !$0.isEmpty }
        if !words.isEmpty {
            return words.prefix(2).compactMap(\.first).map { String($0) }.joined().uppercased()
        }

        return "BD"
    }

    var hasRenderableLogo: Bool {
        normalizedLogoAssetName != nil || !logoFallbackText.isEmpty
    }
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
