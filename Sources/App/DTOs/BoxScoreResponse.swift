import Vapor

struct TeamStatsDTO: Content {
    let goals: Int
    let assists: Int
    let shots: Int
    let shotsOnGoal: Int?
    let saves: Int
    let groundBalls: Int
    let faceoffsWon: Int
    let faceoffsLost: Int
    let turnovers: Int
    let penalties: Int

    init(from stats: GameStats) {
        self.goals = stats.goals
        self.assists = stats.assists
        self.shots = stats.shots
        self.shotsOnGoal = stats.shotsOnGoal
        self.saves = stats.saves
        self.groundBalls = stats.groundBalls
        self.faceoffsWon = stats.faceoffsWon
        self.faceoffsLost = stats.faceoffsLost
        self.turnovers = stats.turnovers
        self.penalties = stats.penalties
    }
}

struct PlayerStatsDTO: Content {
    let playerName: String
    let number: String?
    let position: String?
    let goals: Int
    let assists: Int
    let points: Int
    let shots: Int
    let saves: Int?
    let groundBalls: Int?
    let faceoffsWon: Int?
    let faceoffsLost: Int?
    let turnovers: Int?

    init(from stats: PlayerGameStats) {
        let player = stats.player
        self.playerName = "\(player.firstName) \(player.lastName)"
        self.number = player.number
        self.position = player.position
        self.goals = stats.goals
        self.assists = stats.assists
        self.points = stats.points
        self.shots = stats.shots
        self.saves = stats.saves
        self.groundBalls = stats.groundBalls
        self.faceoffsWon = stats.faceoffsWon
        self.faceoffsLost = stats.faceoffsLost
        self.turnovers = stats.turnovers
    }
}

struct BoxScoreResponse: Content {
    let game: GameResponse
    let homeTeamStats: TeamStatsDTO?
    let awayTeamStats: TeamStatsDTO?
    let homePlayers: [PlayerStatsDTO]
    let awayPlayers: [PlayerStatsDTO]

    init(from gameModel: Game) {
        self.game = GameResponse(from: gameModel)

        let allGameStats = gameModel.gameStats
        self.homeTeamStats = allGameStats.first(where: { $0.isHome })
            .map { TeamStatsDTO(from: $0) }
        self.awayTeamStats = allGameStats.first(where: { !$0.isHome })
            .map { TeamStatsDTO(from: $0) }

        let homeTeamID = gameModel.$homeTeam.id
        let awayTeamID = gameModel.$awayTeam.id

        self.homePlayers = gameModel.playerStats
            .filter { $0.player.$team.id == homeTeamID }
            .map { PlayerStatsDTO(from: $0) }

        self.awayPlayers = gameModel.playerStats
            .filter { $0.player.$team.id == awayTeamID }
            .map { PlayerStatsDTO(from: $0) }
    }
}
