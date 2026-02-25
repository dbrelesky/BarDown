import Vapor

struct ScheduleGameDTO: Content {
    let gameID: UUID
    let opponent: TeamBrief
    let isHome: Bool
    let score: String?
    let status: String
    let startTime: Date

    init(from game: Game, forTeamID teamID: UUID) {
        self.gameID = game.id!
        let isHomeGame = game.$homeTeam.id == teamID
        self.isHome = isHomeGame
        self.opponent = isHomeGame
            ? TeamBrief(from: game.awayTeam)
            : TeamBrief(from: game.homeTeam)

        if game.status == "final" {
            let teamScore = isHomeGame ? game.homeScore : game.awayScore
            let opponentScore = isHomeGame ? game.awayScore : game.homeScore
            let result = teamScore > opponentScore ? "W" : "L"
            self.score = "\(result) \(teamScore)-\(opponentScore)"
        } else {
            self.score = nil
        }

        self.status = game.status
        self.startTime = game.startTime
    }
}

struct ScheduleResponse: Content {
    let team: TeamBrief
    let games: [ScheduleGameDTO]
}
