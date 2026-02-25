import Vapor

/// Scrapes game data from the NCAA's GraphQL API (sdataprod.ncaa.com).
///
/// ## Data Source (2026-02-25 audit)
///
/// The NCAA Casablanca JSON API (`data.ncaa.com/casablanca/...`) returns NoSuchKey for
/// 2026 season dates — that endpoint is deprecated. The scoreboard now uses Apollo
/// persisted queries at `sdataprod.ncaa.com`. The SHA-256 hash for `GetContests_web`
/// is embedded in the scoreboard page HTML and is stable between NCAA deployments.
///
/// ## Strategy
/// 1. Fetch `ncaa.com/scoreboard/lacrosse-men/d1` to extract the `GetContests_web` hash.
/// 2. Cache hash; refresh automatically on `PERSISTED_QUERY_NOT_FOUND`.
/// 3. Query `GetContests_web` with `seasonYear: 2025` (NCAA uses academic-year start).
///
/// ## Team Logos
/// `https://www.ncaa.com/sites/default/files/images/logos/schools/bgl/{seoname}.svg`
/// Verified working for all D1 men's lacrosse teams.
///
/// ## Missing vs Casablanca
/// - Win/loss records (DataReconciler accumulates these from game results)
/// - Quarter-by-quarter scoring (not in scoreboard query)
struct NCAAAPIScraper {
    let app: Application

    /// Cached `GetContests_web` SHA-256 hash. Refreshed on PERSISTED_QUERY_NOT_FOUND.
    nonisolated(unsafe) static var cachedQueryHash: String? = nil

    /// NCAA uses academic-year start as seasonYear (2025-26 season → 2025).
    private static let seasonYear = 2025
    private static let graphqlURL = "https://sdataprod.ncaa.com"
    private static let scoreboardPageURL = "https://www.ncaa.com/scoreboard/lacrosse-men/d1"
    private static let logoBaseURL = "https://www.ncaa.com/sites/default/files/images/logos/schools/bgl"

    // MARK: - GraphQL Response Models

    private struct GraphQLResponse: Codable {
        let data: ContestsWrapper?
        let errors: [GQLError]?

        struct ContestsWrapper: Codable {
            let contests: [Contest]
        }

        struct GQLError: Codable {
            let message: String
            let extensions: Extensions?
            struct Extensions: Codable {
                let code: String
            }
        }
    }

    private struct Contest: Codable {
        let contestId: Int
        let gameState: String       // "P" = scheduled, "F" = final, other = live
        let currentPeriod: String
        let contestClock: String
        let startTimeEpoch: Int
        let teams: [ContestTeam]
    }

    private struct ContestTeam: Codable {
        let isHome: Bool
        let seoname: String
        let nameShort: String
        let name6Char: String
        let teamRank: Int?
        let score: Int?
        let conferenceSeo: String
    }

    // MARK: - Public API

    /// Fetches all D1 men's lacrosse games for a given date.
    func fetchScoreboard(date: Date) async -> [ScrapedGame] {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yyyy"
        formatter.timeZone = TimeZone(identifier: "America/New_York")
        let contestDate = formatter.string(from: date)
        return await fetchContests(contestDate: contestDate, attempt: 1)
    }

    /// Fetches games for a date, filtered to teams in a specific conference.
    func fetchScoreboard(date: Date, conference: String) async -> [ScrapedGame] {
        let allGames = await fetchScoreboard(date: date)
        let conferenceLower = conference.lowercased()
        return allGames.filter { game in
            let homeConf = game.homeConference?.lowercased() ?? ""
            let awayConf = game.awayConference?.lowercased() ?? ""
            return homeConf.contains(conferenceLower) || awayConf.contains(conferenceLower)
        }
    }

    // MARK: - Private Fetch

    private func fetchContests(contestDate: String, attempt: Int) async -> [ScrapedGame] {
        if NCAAAPIScraper.cachedQueryHash == nil {
            NCAAAPIScraper.cachedQueryHash = await fetchQueryHash()
        }
        guard let hash = NCAAAPIScraper.cachedQueryHash else {
            app.logger.error("NCAAAPIScraper: Could not obtain GraphQL hash from scoreboard page")
            return []
        }

        let vars = """
            {"contestDate":"\(contestDate)","sportCode":"MLA","division":1,"seasonYear":\(Self.seasonYear)}
            """
        let exts = """
            {"persistedQuery":{"version":1,"sha256Hash":"\(hash)"}}
            """
        guard let encodedVars = vars.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let encodedExts = exts.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return []
        }

        let urlStr = "\(Self.graphqlURL)?meta=GetContests_web&extensions=\(encodedExts)&variables=\(encodedVars)"
        let uri = URI(string: urlStr)

        do {
            let response = try await app.client.get(uri) { req in
                req.headers.add(name: .userAgent, value: "BarDown/1.0")
                req.headers.add(name: .accept, value: "application/json")
            }

            let body = try response.content.decode(GraphQLResponse.self)

            // Hash expired — retry once with a fresh hash
            if let errors = body.errors,
               errors.contains(where: { $0.extensions?.code == "PERSISTED_QUERY_NOT_FOUND" }),
               attempt < 2 {
                app.logger.info("NCAAAPIScraper: Hash expired, refreshing")
                NCAAAPIScraper.cachedQueryHash = await fetchQueryHash()
                return await fetchContests(contestDate: contestDate, attempt: attempt + 1)
            }

            guard let contests = body.data?.contests else {
                if let errors = body.errors {
                    app.logger.warning("NCAAAPIScraper: GraphQL errors: \(errors.map { $0.message })")
                }
                return []
            }

            let games = contests.compactMap { mapContest($0) }
            app.logger.info("NCAAAPIScraper: Fetched \(games.count) games for \(contestDate)")
            return games

        } catch {
            app.logger.error("NCAAAPIScraper: Request failed for \(contestDate): \(error)")
            return []
        }
    }

    // MARK: - Hash Fetching

    private func fetchQueryHash() async -> String? {
        let uri = URI(string: Self.scoreboardPageURL)
        do {
            let response = try await app.client.get(uri) { req in
                req.headers.add(name: .userAgent, value: "BarDown/1.0")
            }
            guard let body = response.body,
                  let html = body.getString(at: body.readerIndex, length: body.readableBytes) else {
                return nil
            }
            return extractHash(from: html)
        } catch {
            app.logger.error("NCAAAPIScraper: Failed to fetch scoreboard page for hash: \(error)")
            return nil
        }
    }

    private func extractHash(from html: String) -> String? {
        let marker = #""GetContests_web":""#
        guard let start = html.range(of: marker)?.upperBound else { return nil }
        let remaining = html[start...]
        guard let end = remaining.firstIndex(of: "\"") else { return nil }
        let hash = String(remaining[remaining.startIndex..<end])
        guard hash.count == 64, hash.allSatisfy({ $0.isHexDigit }) else { return nil }
        app.logger.info("NCAAAPIScraper: Extracted fresh hash \(hash.prefix(8))...")
        return hash
    }

    // MARK: - Mapping

    private func mapContest(_ contest: Contest) -> ScrapedGame? {
        guard let home = contest.teams.first(where: { $0.isHome }),
              let away = contest.teams.first(where: { !$0.isHome }) else {
            app.logger.warning("NCAAAPIScraper: Contest \(contest.contestId) missing a team")
            return nil
        }

        let status: String
        switch contest.gameState {
        case "F": status = "final"
        case "P": status = "scheduled"
        default:  status = "live"
        }

        let startTime = Date(timeIntervalSince1970: TimeInterval(contest.startTimeEpoch))

        // conferenceSeo uses hyphens ("big-ten"); conferenceNameMap uses spaces ("big ten")
        let homeConf = home.conferenceSeo.replacingOccurrences(of: "-", with: " ")
        let awayConf = away.conferenceSeo.replacingOccurrences(of: "-", with: " ")

        return ScrapedGame(
            homeTeamName: home.nameShort,
            awayTeamName: away.nameShort,
            homeScore: home.score ?? 0,
            awayScore: away.score ?? 0,
            status: status,
            period: contest.currentPeriod.isEmpty ? nil : contest.currentPeriod,
            clock: contest.contestClock.isEmpty ? nil : contest.contestClock,
            startTime: startTime,
            startTimeEpoch: String(contest.startTimeEpoch),
            externalGameID: String(contest.contestId),
            conferenceID: nil,
            homeConference: homeConf,
            awayConference: awayConf,
            homeTeamShort: home.name6Char.uppercased(),
            awayTeamShort: away.name6Char.uppercased(),
            homeTeamFull: home.nameShort,
            awayTeamFull: away.nameShort,
            homeRank: home.teamRank.map { String($0) },
            awayRank: away.teamRank.map { String($0) },
            homeRecord: nil,
            awayRecord: nil,
            homeLogoURL: "\(Self.logoBaseURL)/\(home.seoname).svg",
            awayLogoURL: "\(Self.logoBaseURL)/\(away.seoname).svg"
        )
    }
}
