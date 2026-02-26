import Vapor

struct QuarterScoreDTO: Content {
    let quarter: Int
    let homeScore: Int
    let awayScore: Int

    init(from qs: QuarterScore) {
        self.quarter = qs.quarter
        self.homeScore = qs.homeScore
        self.awayScore = qs.awayScore
    }
}

struct GameResponse: Content {
    let id: UUID
    let homeTeam: TeamBrief
    let awayTeam: TeamBrief
    let homeScore: Int
    let awayScore: Int
    let status: String
    let period: String?
    let clock: String?
    let startTime: Date
    let quarterScores: [QuarterScoreDTO]
    let boxScoreURL: String?

    init(from game: Game) {
        self.id = game.id!
        self.homeTeam = TeamBrief(from: game.homeTeam)
        self.awayTeam = TeamBrief(from: game.awayTeam)
        self.homeScore = game.homeScore
        self.awayScore = game.awayScore
        self.status = game.status
        self.period = game.period
        self.clock = game.clock
        self.startTime = game.startTime
        self.quarterScores = game.quarterScores.map { QuarterScoreDTO(from: $0) }
        self.boxScoreURL = game.ncaaGameID.map {
            "https://www.ncaa.com/game/lacrosse-men/d1/\($0)"
        }
    }
}
