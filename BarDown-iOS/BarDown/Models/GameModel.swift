import Foundation

enum GameStatus: Int, Comparable {
    case live = 0
    case scheduled = 1
    case final_ = 2   // 'final' is a reserved Swift keyword — use final_ with raw value "final"

    static func < (lhs: GameStatus, rhs: GameStatus) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

struct GameModel: Decodable, Identifiable {
    let id: UUID
    let homeTeam: TeamModel
    let awayTeam: TeamModel
    let homeScore: Int
    let awayScore: Int
    let status: String      // "scheduled", "live", "final"
    let period: String?
    let clock: String?
    let startTime: Date
    let quarterScores: [QuarterScoreModel]
    let boxScoreURL: String?

    var gameStatus: GameStatus {
        switch status {
        case "live":    return .live
        case "final":   return .final_
        default:        return .scheduled
        }
    }

    var isLive: Bool      { status == "live" }
    var isFinal: Bool     { status == "final" }
    var isScheduled: Bool { status == "scheduled" }
}

struct QuarterScoreModel: Decodable {
    let quarter: Int
    let homeScore: Int
    let awayScore: Int
}

extension GameModel {
    static var placeholder: GameModel {
        GameModel(
            id: UUID(),
            homeTeam: .placeholder,
            awayTeam: .placeholder,
            homeScore: 0,
            awayScore: 0,
            status: "scheduled",
            period: nil,
            clock: nil,
            startTime: .now,
            quarterScores: [],
            boxScoreURL: nil
        )
    }
}
