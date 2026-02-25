# Phase 1: Data Foundation - Research

**Researched:** 2026-02-24
**Domain:** Backend scraping pipeline, REST API, PostgreSQL data storage (server-side Swift)
**Confidence:** MEDIUM — StatBroadcast page structure is unverified (JS-rendered, no public API docs), but stack choices and architecture patterns are well-supported

## Summary

Phase 1 builds a Vapor (server-side Swift) backend that scrapes college lacrosse game data, stores it in PostgreSQL via Fluent ORM, and serves REST JSON endpoints for the iOS app. The project decision to use a shared Swift monorepo (Vapor backend + SwiftUI client) means the backend is written in Swift using Vapor 4, deployed via Docker to Railway ($5-10/month), with managed PostgreSQL included in Railway's usage-based pricing.

The primary data source is StatBroadcast, which renders scoreboards via client-side JavaScript (`StatBroadcastScoreboard` class calling `loadPage()`). This means the visible HTML contains no game data — it is loaded dynamically. The first implementation task must be a hands-on audit of StatBroadcast's network requests (using browser dev tools) to discover the actual XHR/JSON endpoints the JavaScript calls. The NCAA also provides a public JSON API at `data.ncaa.com/casablanca/scoreboard/lacrosse-men/d1/{yyyy}/{mm}/{dd}/scoreboard.json` that returns structured game data — this serves as a valuable supplementary/fallback data source for scores and schedules, though it may lack the detailed player-level box score data that StatBroadcast provides.

**Primary recommendation:** Build a Vapor 4 backend with Fluent/PostgreSQL on Railway. Invest the first task in a thorough StatBroadcast network audit before writing any scraping code. Use the NCAA JSON API as a supplementary data source for scoreboard-level data and game metadata.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- Scrape every 30-60 seconds during live games for near real-time scores
- Phase 1 conferences: Big East, ACC, Big Ten, Patriot League, Ivy League
- Remaining D1 conferences added in a follow-up (not this phase)
- On scrape failure: retry a few times, then serve last successful data — API stays up even when scraping is broken
- Claude to investigate StatBroadcast page structure and determine URL patterns, parsing approach
- Store both team-level totals AND individual player stat lines from day one (ready for Phase 5: Game Detail)
- Lacrosse stats to capture: goals, assists, shots, saves, ground balls, faceoffs won/lost, turnovers, penalties
- Current 2026 season only — no historical seasons in v1 schema
- Quarter-by-quarter scoring breakdown stored per game
- Budget: $10-25/month for all backend services

### Claude's Discretion
- Team identification strategy (internal IDs vs StatBroadcast IDs vs hybrid)
- Logo sourcing approach (bundled in app vs served from API/CDN)
- Cloud provider and deployment platform selection
- Language/runtime choice (TypeScript, Python, Swift, etc.)
- Whether scraper and API are one service or separate deployments
- Scrape scheduling logic (smart scheduling based on game times vs fixed intervals)
- Database ORM and migration tooling

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| DATA-01 | Cloud backend scrapes StatBroadcast on schedule for game data across all D1 conferences | StatBroadcast audit needed (JS-rendered pages); NCAA JSON API as supplementary source; Vapor client + SwiftSoup for scraping; NIO RepeatedTask or VaporCron for scheduling; Phase 1 covers 5 conferences |
| DATA-02 | Backend serves clean REST JSON API consumed by the iOS app | Vapor 4 routing + Content protocol provides automatic Codable JSON serialization; shared Swift models between backend and iOS client |
| DATA-03 | App never directly accesses scraped sources — all data flows through our API | Architecture enforced by design — iOS app only knows about our REST endpoints |
| DATA-04 | Backend stores master database of teams, players, schedules, and game results | Fluent ORM with PostgreSQL driver; models for Team, Player, Game, GameStats, PlayerStats, Schedule; Railway managed Postgres |
</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Vapor | 4.89+ | HTTP server framework, routing, middleware | Only production-grade Swift server framework; project decision is shared Swift monorepo |
| Fluent | 4.8+ | ORM — models, migrations, queries | Vapor's official ORM; async/await, type-safe queries |
| FluentPostgresDriver | 2.7+ | PostgreSQL database driver | Official Fluent driver for Postgres |
| SwiftSoup | 2.7+ | HTML parsing and DOM traversal | The standard Swift HTML parser; CSS selectors, jQuery-like API; pure Swift, works on Linux |
| AsyncHTTPClient | (via Vapor) | Outbound HTTP requests for scraping | Built into Vapor as `req.client` / `app.client`; non-blocking, NIO-based |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| VaporCron | 2.6+ | Cron-style job scheduling | For scheduled scraping at fixed intervals; supports second-level granularity |
| QueuesFluentDriver | 3.0+ | Job queue backed by PostgreSQL | If scrape jobs need persistence/retry beyond simple timers; avoids Redis dependency |
| Swift Argument Parser | (via Vapor) | CLI commands (migrate, seed) | Already included in Vapor for `swift run App migrate` etc. |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| VaporCron | Swift NIO RepeatedTask | RepeatedTask is simpler (no dependency) but lacks cron expressions; fine for fixed 30s intervals |
| SwiftSoup | Direct regex parsing | Regex is fragile against HTML changes; SwiftSoup provides proper DOM traversal |
| Railway | Fly.io | Fly.io is more powerful but starts at $29/mo for support plan; Railway Hobby is $5/mo with included Postgres |
| Fluent | Raw SQL via PostgresNIO | More control but loses migration management, type safety, and relationship loading |

**Installation (Package.swift dependencies):**
```swift
dependencies: [
    .package(url: "https://github.com/vapor/vapor.git", from: "4.89.0"),
    .package(url: "https://github.com/vapor/fluent.git", from: "4.8.0"),
    .package(url: "https://github.com/vapor/fluent-postgres-driver.git", from: "2.7.0"),
    .package(url: "https://github.com/scinfu/SwiftSoup.git", from: "2.7.0"),
    .package(url: "https://github.com/MihaelIsaev/VaporCron.git", from: "2.6.0"),
]
```

## Architecture Patterns

### Recommended Project Structure
```
BarDown/
├── Package.swift
├── Dockerfile
├── Sources/
│   ├── App/
│   │   ├── configure.swift          # DB, middleware, scheduled jobs
│   │   ├── routes.swift             # Route registration
│   │   ├── entrypoint.swift         # @main entry point
│   │   ├── Models/                  # Fluent models
│   │   │   ├── Team.swift
│   │   │   ├── Player.swift
│   │   │   ├── Game.swift
│   │   │   ├── GameStats.swift
│   │   │   ├── PlayerGameStats.swift
│   │   │   └── Conference.swift
│   │   ├── Migrations/              # Database migrations
│   │   │   ├── CreateConference.swift
│   │   │   ├── CreateTeam.swift
│   │   │   ├── CreatePlayer.swift
│   │   │   ├── CreateGame.swift
│   │   │   ├── CreateGameStats.swift
│   │   │   └── CreatePlayerGameStats.swift
│   │   ├── Controllers/             # Route handlers grouped by resource
│   │   │   ├── GameController.swift
│   │   │   ├── TeamController.swift
│   │   │   └── ScheduleController.swift
│   │   ├── Scraper/                 # Scraping logic isolated from API
│   │   │   ├── StatBroadcastScraper.swift
│   │   │   ├── NCAAAPIScraper.swift
│   │   │   ├── ScraperScheduler.swift
│   │   │   └── HTMLParsers/
│   │   │       ├── ScoreboardParser.swift
│   │   │       └── BoxScoreParser.swift
│   │   └── DTOs/                    # Response shapes (decoupled from DB models)
│   │       ├── GameResponse.swift
│   │       ├── BoxScoreResponse.swift
│   │       └── ScheduleResponse.swift
│   └── Shared/                      # Shared types for future iOS client
│       └── (empty for now — populated when iOS target added)
├── Tests/
│   └── AppTests/
└── docker-compose.yml               # Local dev: Postgres container
```

### Pattern 1: Scraper as Internal Service (Single Deployment)
**What:** The scraper and API live in the same Vapor process. The scraper runs on a background task/cron schedule, writes to PostgreSQL. The API serves from PostgreSQL. They share the same database connection pool.
**When to use:** Always for this project — budget constraint ($10-25/mo) means one Railway service, not two. The scraper is lightweight (HTTP requests + HTML parsing) and won't block the API event loop because Vapor is non-blocking.
**Example:**
```swift
// In configure.swift — schedule scraping on app boot
func configure(_ app: Application) async throws {
    // Database
    app.databases.use(.postgres(
        configuration: .init(
            hostname: Environment.get("DATABASE_HOST") ?? "localhost",
            username: Environment.get("DATABASE_USERNAME") ?? "vapor",
            password: Environment.get("DATABASE_PASSWORD") ?? "vapor",
            database: Environment.get("DATABASE_NAME") ?? "bardown",
            tls: .disable
        )
    ), as: .psql)

    // Migrations
    app.migrations.add(CreateConference())
    app.migrations.add(CreateTeam())
    app.migrations.add(CreateGame())
    // ...

    // Start scraper on a repeating schedule
    try app.cron.schedule(ScoreboardScrapeJob.self)
        .everySecond(30)  // VaporCron syntax

    try routes(app)
}
```

### Pattern 2: Resilient Scraping with Fallback
**What:** On scrape failure, retry 2-3 times with backoff, then serve stale data. Never let the API go down because scraping broke.
**When to use:** Always — this is a locked user decision.
**Example:**
```swift
struct ScoreboardScrapeJob: VaporCronSchedulable {
    static var expression: String { "*/30 * * * * *" } // every 30 seconds

    func task(on app: Application) async throws {
        do {
            let html = try await app.client.get(URI(string: scoreboardURL))
            let games = try ScoreboardParser.parse(html.body)
            try await persistGames(games, on: app.db)
        } catch {
            app.logger.error("Scrape failed: \(error)")
            // Data in DB remains — API continues serving last good data
            // Retry logic handled by next scheduled run (30s later)
        }
    }
}
```

### Pattern 3: DTO Layer (Decouple API Responses from DB Models)
**What:** API responses use separate `Codable` structs (DTOs) rather than exposing Fluent models directly. This lets the API shape evolve independently of the database schema.
**When to use:** Always — prevents leaking database internals (like `$parent` wrappers) to the iOS client.
**Example:**
```swift
struct GameResponse: Content {
    let id: UUID
    let homeTeam: TeamBrief
    let awayTeam: TeamBrief
    let homeScore: Int
    let awayScore: Int
    let status: GameStatus
    let period: String?
    let clock: String?
    let startTime: Date
    let quarterScores: [QuarterScore]
}

struct TeamBrief: Content {
    let id: UUID
    let name: String
    let abbreviation: String
    let conference: String
    let logoURL: String?
    let record: String?
    let ranking: Int?
}
```

### Anti-Patterns to Avoid
- **Scraping in route handlers:** Never scrape StatBroadcast inside an API request. Always serve from the database. Scraping is a background job.
- **Exposing Fluent models as API responses:** Fluent models have property wrappers (`@Field`, `@Parent`) that serialize oddly. Use DTOs.
- **Hardcoding conference URLs:** Store conference metadata (name, StatBroadcast confid, scrape URL) in the database or a config file, not scattered through code.
- **Blocking the event loop:** SwiftSoup parsing and HTTP requests are fine (async/non-blocking via NIO), but avoid any synchronous file I/O or Thread.sleep.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| HTML parsing | Regex-based HTML extraction | SwiftSoup | HTML is not regular; regex breaks on whitespace changes, attribute reordering, nested tags |
| Database migrations | Raw SQL files executed manually | Fluent Migrations | Fluent tracks migration state, supports revert, and is type-checked at compile time |
| HTTP client | URLSession on Linux | Vapor's built-in Client (AsyncHTTPClient) | URLSession has limited Linux support; Vapor's client is NIO-native and non-blocking |
| JSON serialization | Manual JSON string building | Vapor Content protocol (Codable) | Content auto-serializes/deserializes with proper Content-Type headers |
| Cron scheduling | Custom Timer/sleep loops | VaporCron or NIO RepeatedTask | Handles edge cases (drift, overlapping runs, app lifecycle) |
| Environment config | Hardcoded values | Vapor's Environment.get() | Reads from process environment; works with Railway's env var injection |

**Key insight:** Vapor's ecosystem already solves every infrastructure problem this phase needs. The only custom code should be the scraper parsers (StatBroadcast HTML structure) and the data model definitions.

## Common Pitfalls

### Pitfall 1: StatBroadcast is JavaScript-Rendered
**What goes wrong:** Fetching the scoreboard URL returns an HTML shell with no game data. The `StatBroadcastScoreboard` JavaScript class loads data dynamically via XHR after page load.
**Why it happens:** Many assume web pages serve static HTML. StatBroadcast uses client-side rendering.
**How to avoid:** Before writing any parser, open browser dev tools on a live StatBroadcast scoreboard, go to the Network tab, filter by XHR/Fetch, and document the actual data endpoints the JS calls. These XHR endpoints likely return HTML fragments or JSON that can be fetched directly — no headless browser needed.
**Warning signs:** SwiftSoup parsing returns empty results or "No events found" text.

### Pitfall 2: Fluent Model Property Wrapper Serialization
**What goes wrong:** Returning a Fluent model directly from a route serializes internal property wrapper metadata (e.g., `$parent` becomes a nested object with `id` only, `@OptionalField` serializes differently than expected).
**Why it happens:** Fluent's property wrappers implement custom `Codable` conformance for database operations, not for clean JSON APIs.
**How to avoid:** Always map Fluent models to plain DTOs before returning from route handlers.
**Warning signs:** iOS client gets unexpected JSON structure, nested `id`-only objects for relations.

### Pitfall 3: Railway Cold Starts
**What goes wrong:** Railway Hobby tier spins down idle services. First request after idle period takes 5-10 seconds. Scheduled scraping jobs may miss their window.
**Why it happens:** Railway hibernates services that receive no traffic to save resources on the Hobby plan.
**How to avoid:** Keep the service warm with a simple health-check cron (or accept ~10s startup delay). Alternatively, the scraper's own 30-second schedule acts as a keep-alive during game times. Configure Railway to not sleep if the budget allows.
**Warning signs:** API returns timeouts after periods of inactivity; stale data during game days.

### Pitfall 4: Scraper Overlap / Race Conditions
**What goes wrong:** A scrape job takes longer than 30 seconds (network timeout, large response), and the next job starts before the first finishes. Two jobs write conflicting data.
**Why it happens:** Fixed-interval scheduling doesn't account for job duration.
**How to avoid:** Use a simple `@Sendable` flag or actor to skip a scrape cycle if the previous one is still running. Log when skips occur.
**Warning signs:** Duplicate game records, inconsistent scores, database constraint violations.

### Pitfall 5: FoundationNetworking on Linux
**What goes wrong:** Swift's `URLSession` and `Foundation` networking behave differently on Linux vs macOS. Some APIs are missing or behave unexpectedly.
**Why it happens:** Vapor runs in Docker on Linux (Ubuntu). Swift Foundation on Linux is a separate implementation.
**How to avoid:** Use Vapor's built-in `Client` (AsyncHTTPClient) exclusively for all HTTP requests. Never import `FoundationNetworking` directly. The Vapor Dockerfile template includes a comment about uncommenting FoundationNetworking/FoundationXML if needed.
**Warning signs:** Compilation errors on Linux that don't appear on macOS; runtime crashes in Docker.

### Pitfall 6: NCAA API Rate Limits
**What goes wrong:** The NCAA's `data.ncaa.com` endpoints and the henrygd/ncaa-api wrapper have rate limits (5 req/sec/IP for the wrapper). Aggressive polling burns through limits.
**Why it happens:** Treating the NCAA API like a local database and calling it on every user request.
**How to avoid:** Use the NCAA API only for periodic scheduled scrapes (same as StatBroadcast). Cache everything in PostgreSQL. The API serves from the database, never proxies to NCAA.
**Warning signs:** 429 Too Many Requests responses; empty data during peak game times.

## Code Examples

### Fluent Model Definition
```swift
// Source: https://docs.vapor.codes/fluent/overview/
final class Game: Model, @unchecked Sendable {
    static let schema = "games"

    @ID(key: .id) var id: UUID?

    @Parent(key: "home_team_id") var homeTeam: Team
    @Parent(key: "away_team_id") var awayTeam: Team

    @Field(key: "home_score") var homeScore: Int
    @Field(key: "away_score") var awayScore: Int
    @Field(key: "status") var status: String      // "scheduled", "live", "final"
    @Field(key: "period") var period: String?
    @Field(key: "clock") var clock: String?
    @Field(key: "start_time") var startTime: Date
    @Field(key: "season") var season: Int          // 2026

    @OptionalField(key: "external_id") var externalID: String?  // StatBroadcast game ID
    @OptionalField(key: "ncaa_game_id") var ncaaGameID: String? // NCAA API game ID

    @Children(for: \.$game) var quarterScores: [QuarterScore]
    @Children(for: \.$game) var playerStats: [PlayerGameStats]

    init() {}
}
```

### Scraping with Vapor Client + SwiftSoup
```swift
// Source: https://docs.vapor.codes/basics/client/ + https://github.com/scinfu/SwiftSoup
import SwiftSoup

struct StatBroadcastScraper {
    let app: Application

    func scrapeScoreboard(conferenceID: String) async throws -> [ScrapedGame] {
        let url = "https://stats.statbroadcast.com/scoreboard/\(dataEndpoint)?confid=\(conferenceID)&sport=lcgame&gender=M"

        let response = try await app.client.get(URI(string: url))
        guard let body = response.body,
              let html = body.getString(at: body.readerIndex, length: body.readableBytes) else {
            throw ScraperError.emptyResponse
        }

        let doc = try SwiftSoup.parse(html)
        // Parse game elements — exact selectors TBD after StatBroadcast audit
        let gameElements = try doc.select(".game-card") // placeholder selector

        return try gameElements.map { element in
            try parseGameElement(element)
        }
    }
}
```

### NCAA JSON API Integration
```swift
// Source: Verified — NCAA returns JSON from data.ncaa.com/casablanca endpoints
struct NCAAAPIScraper {
    let app: Application

    struct NCAAScoreboard: Codable {
        let games: [NCAAGameWrapper]
        let updated_at: String?
    }

    struct NCAAGameWrapper: Codable {
        let game: NCAAGame
    }

    struct NCAAGame: Codable {
        let gameID: String
        let gameState: String          // "final", "live", "pre"
        let startTime: String
        let startDate: String
        let currentPeriod: String?
        let contestClock: String?
        let home: NCAATeamScore
        let away: NCAATeamScore
    }

    struct NCAATeamScore: Codable {
        let score: String?
        let winner: Bool?
        let names: NCAATeamNames
        let rank: String?
    }

    struct NCAATeamNames: Codable {
        let char6: String
        let short: String
        let full: String
        let seo: String
    }

    func fetchScoreboard(date: Date) async throws -> NCAAScoreboard {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        let datePath = formatter.string(from: date)

        let url = "https://data.ncaa.com/casablanca/scoreboard/lacrosse-men/d1/\(datePath)/scoreboard.json"
        let response = try await app.client.get(URI(string: url))
        return try response.content.decode(NCAAScoreboard.self)
    }
}
```

### Route Controller with DTO Mapping
```swift
// Source: https://docs.vapor.codes/basics/routing/
struct GameController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let games = routes.grouped("api", "v1", "games")
        games.get("today", use: todaysGames)
        games.get(":gameID", "boxscore", use: boxScore)
    }

    @Sendable
    func todaysGames(req: Request) async throws -> [GameResponse] {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!

        let games = try await Game.query(on: req.db)
            .filter(\.$startTime >= today)
            .filter(\.$startTime < tomorrow)
            .with(\.$homeTeam)
            .with(\.$awayTeam)
            .with(\.$quarterScores)
            .sort(\.$startTime)
            .all()

        return games.map { GameResponse(from: $0) }
    }

    @Sendable
    func boxScore(req: Request) async throws -> BoxScoreResponse {
        guard let gameID = req.parameters.get("gameID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid game ID")
        }

        let game = try await Game.query(on: req.db)
            .filter(\.$id == gameID)
            .with(\.$homeTeam)
            .with(\.$awayTeam)
            .with(\.$quarterScores)
            .with(\.$playerStats) { $0.with(\.$player) }
            .first()

        guard let game else { throw Abort(.notFound) }
        return BoxScoreResponse(from: game)
    }
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Vapor 3 (EventLoopFuture everywhere) | Vapor 4 with full async/await | Vapor 4.0 (2020), async/await support matured 2023+ | Use async/await exclusively; no EventLoopFuture |
| URLSession for HTTP on Linux | AsyncHTTPClient via Vapor Client | Swift 5.5+ | Always use `app.client` / `req.client`, never URLSession |
| Fluent 3 (different API surface) | Fluent 4 with property wrappers | 2020 | Use @Field, @Parent, @Children property wrappers |
| NCAA stats.ncaa.org (old) | data.ncaa.com/casablanca endpoints | ~2023 | Old endpoint deprecated; casablanca endpoints are current but may have gaps |

**Deprecated/outdated:**
- Vapor 3 APIs and EventLoopFuture-based patterns — do not follow pre-2023 tutorials without checking for async equivalents
- `stats.ncaa.org` scrapers — the old NCAA stats site has been replaced

## Discretion Recommendations

### Team Identification: Hybrid Approach (RECOMMENDED)
Use internal UUIDs as primary keys. Store both StatBroadcast IDs and NCAA IDs as optional external fields on the Team model. This allows matching across data sources and survives if either source changes their IDs. Seed the teams table with a migration that maps known conferences/teams to both ID systems.

### Cloud Provider: Railway (RECOMMENDED)
Railway Hobby plan at $5/month includes PostgreSQL, Docker deployment, and auto-deploy from GitHub. Total estimated cost: $5-10/month (well within $10-25 budget). Railway has a Vapor template and proven Swift deployment support. Fly.io is a viable alternative but starts at a higher price point ($29/mo for support).

### Single Service Deployment (RECOMMENDED)
Run scraper and API in the same Vapor process. Budget doesn't support two services. The scraper is lightweight (a few HTTP requests + HTML parsing every 30 seconds) and runs on background tasks — it won't impact API performance because Vapor is non-blocking.

### Smart Scheduling (RECOMMENDED)
Instead of scraping all conferences every 30 seconds 24/7, implement schedule-aware scraping:
- Scrape every 30 seconds only for conferences with live games (check game start times from the database)
- Scrape every 5-15 minutes during "active hours" (noon-midnight ET on game days) to catch schedule updates
- Scrape once per hour during off-hours for schedule/roster changes
This saves compute resources and stays well within Railway's $5 credit.

### Logo Sourcing: Bundled in App (RECOMMENDED for Phase 1)
For 5 conferences (~50-60 teams), bundle logo assets directly in the iOS app. This avoids CDN costs, works offline, and is simpler to implement. The API returns a team identifier that the iOS app maps to a local asset. Can revisit with a CDN approach if the full D1 expansion (350+ teams) makes bundling impractical.

## Open Questions

1. **StatBroadcast XHR Endpoints**
   - What we know: The scoreboard pages use `StatBroadcastScoreboard` JS class to dynamically load data. The raw HTML contains no game data.
   - What's unclear: The exact XHR URLs, response format (JSON vs HTML fragments), authentication/session requirements, rate limits, and whether endpoints vary by conference.
   - Recommendation: First implementation task MUST be a hands-on browser Network tab audit of a live StatBroadcast scoreboard. Document all XHR requests, their URLs, parameters, and response structure. This blocks all scraper development.

2. **StatBroadcast Box Score Page Structure**
   - What we know: Individual game broadcasts are at `stats.statbroadcast.com/broadcast/?id={gameID}&confid={conf}`. They likely also load data dynamically.
   - What's unclear: Whether box score data (player stats, quarter scores) is available via the same XHR pattern or requires different scraping. The page structure and selectors are unknown.
   - Recommendation: Audit the broadcast page during/after a live game alongside the scoreboard audit.

3. **StatBroadcast Conference ID Mapping**
   - What we know: URL parameter `confid=acc` is used for ACC. Other IDs seen: `bigeast`, `sland` (Southland), `caa`.
   - What's unclear: The exact `confid` values for all 5 Phase 1 conferences (Big East, ACC, Big Ten, Patriot League, Ivy League).
   - Recommendation: Systematically check `stats.statbroadcast.com/scoreboards.php` or test known abbreviations (e.g., `bigten`, `b1g`, `patriot`, `ivy`).

4. **NCAA Casablanca API Reliability for Lacrosse**
   - What we know: The scoreboard endpoint returns structured JSON with game data for lacrosse. The henrygd/ncaa-api project wraps these endpoints.
   - What's unclear: Whether box score detail endpoints work for lacrosse (they may 404 or return empty data). The casablanca API has had stability issues with some sports.
   - Recommendation: Test the full set of NCAA endpoints (scoreboard, game detail, boxscore) during the lacrosse season to confirm availability. Use NCAA as supplementary, not primary.

5. **Railway Cold Start Impact on Scraping**
   - What we know: Railway Hobby tier may sleep idle services.
   - What's unclear: Whether the 30-second scrape schedule is enough to keep the service warm, or if Railway hibernation requires explicit configuration.
   - Recommendation: Test after deployment. If cold starts are an issue, investigate Railway's "always on" option or a keep-alive strategy.

## Sources

### Primary (HIGH confidence)
- [Vapor Official Docs — Client](https://docs.vapor.codes/basics/client/) — HTTP client API for outbound requests
- [Vapor Official Docs — Fluent Overview](https://docs.vapor.codes/fluent/overview/) — ORM models, migrations, queries
- [Vapor Official Docs — Queues](https://docs.vapor.codes/advanced/queues/) — Job scheduling and background workers
- [SwiftSoup GitHub](https://github.com/scinfu/SwiftSoup) — HTML parser library, MIT license
- [VaporCron GitHub](https://github.com/MihaelIsaev/VaporCron) — Cron scheduler for Vapor
- [Railway Pricing Docs](https://docs.railway.com/pricing/plans) — Hobby plan $5/mo with included Postgres
- [Railway Vapor Template](https://railway.com/deploy/swift-vapor-openapi-postgres) — Swift + Vapor + Postgres deployment

### Secondary (MEDIUM confidence)
- [SwiftToolkit — Deploy Vapor to Railway/Fly.io](https://www.swifttoolkit.dev/posts/deploy-fly-railway) — Deployment guide (March 2025)
- [NCAA data.ncaa.com Scoreboard JSON](https://data.ncaa.com/casablanca/scoreboard/lacrosse-men/d1/) — Verified returns structured game JSON with scores, teams, status
- [henrygd/ncaa-api GitHub](https://github.com/henrygd/ncaa-api) — Wraps NCAA endpoints; box score and play-by-play routes confirmed
- [Fly.io + Vapor + Managed Postgres](https://twocentstudios.com/2025/06/30/swift-vapor-fly-managed-postgres/) — Alternative hosting guide

### Tertiary (LOW confidence)
- StatBroadcast JS-rendered scoreboard structure — Based on fetching the page and seeing `StatBroadcastScoreboard.loadPage()` with no game data in HTML. Actual XHR endpoints are UNKNOWN and must be audited manually.
- NCAA casablanca box score endpoints for lacrosse — Confirmed for scoreboard level but individual game box scores unverified for lacrosse specifically.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — Vapor 4 + Fluent + PostgreSQL is well-documented, actively maintained, and Railway deployment is proven
- Architecture: HIGH — Single-service Vapor app with background scraping is a standard pattern with clear documentation
- Scraper implementation: LOW — StatBroadcast's actual data endpoints are unknown; requires hands-on audit before any scraping code is written
- Pitfalls: MEDIUM — Based on known issues with Vapor on Linux, Railway hosting, and general web scraping patterns

**Research date:** 2026-02-24
**Valid until:** 2026-03-24 (30 days — stable stack, but StatBroadcast structure could change)
