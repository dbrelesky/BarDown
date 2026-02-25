# Stack Research

**Domain:** Native iOS sports scores app with cloud backend
**Researched:** 2026-02-24
**Confidence:** MEDIUM — WebSearch/WebFetch unavailable; recommendations based on training data (cutoff May 2025), project UI-guidelines.md (compiled Feb 2026 from official sources), and PROJECT.md constraints. Version numbers flagged for validation where uncertain.

---

## Recommended Stack

### Client — iOS App

| Technology | Version | Purpose | Why Recommended | Confidence |
|------------|---------|---------|-----------------|------------|
| SwiftUI | iOS 26+ / Xcode 26 | UI framework | Project mandate. Liquid Glass APIs are SwiftUI-first. No UIKit hybrid needed for a scores app — every screen is lists, cards, and navigation chrome that SwiftUI handles natively. | HIGH |
| Swift | 6.x (ships with Xcode 26) | Language | Required for SwiftUI. Swift 6 strict concurrency checking prevents data races — critical for real-time score updates arriving on background threads. | MEDIUM |
| Swift Data | iOS 26+ | Local persistence | Apple's native persistence layer replaces Core Data boilerplate. Stores favorites, cached scores, team metadata. Macro-based `@Model` syntax integrates naturally with SwiftUI `@Query`. No third-party ORM needed. | MEDIUM |
| Swift Package Manager | Built-in | Dependency management | Only dependency manager Apple officially supports. CocoaPods is maintenance-mode; Carthage is effectively dead. SPM integrates directly into Xcode project settings. | HIGH |

### Client — Networking & Data

| Library | Version | Purpose | Why Recommended | Confidence |
|---------|---------|---------|-----------------|------------|
| Foundation URLSession + async/await | Built-in | HTTP networking | No need for Alamofire in 2026. Native `URLSession` with Swift concurrency (`async let`, `TaskGroup`) handles all API calls. Fewer dependencies = fewer breakages on new OS releases. | HIGH |
| Swift Codable (Foundation) | Built-in | JSON parsing | Native `Codable` with custom `CodingKeys` handles API response mapping. No SwiftyJSON or ObjectMapper needed. | HIGH |
| swift-collections | ~1.1 | OrderedDictionary, Deque | Apple's official collections package. `OrderedDictionary` for maintaining game sort order. `Deque` for play-by-play event buffers. Only add if standard collections prove insufficient. | MEDIUM |

### Client — Real-Time Updates

| Technology | Version | Purpose | Why Recommended | Confidence |
|------------|---------|---------|-----------------|------------|
| Server-Sent Events (SSE) via URLSession | Built-in | Live score streaming | Simpler than WebSockets for one-directional server-to-client score updates. URLSession supports SSE natively. Lower overhead than maintaining a WebSocket connection. The server pushes; the client listens. | MEDIUM |
| APNs (Apple Push Notification service) | Built-in | Push notifications | Required for score alerts when app is backgrounded/killed. Use `UNUserNotificationCenter` for local handling. Server sends via APNs HTTP/2 API. No Firebase wrapper needed — direct APNs is simpler for a single-platform app. | HIGH |
| BackgroundTasks framework | Built-in | Background refresh | `BGAppRefreshTask` to periodically pull latest scores when app is not foregrounded. Ensures cached data stays fresh. | HIGH |

### Server — Cloud Backend

| Technology | Version | Purpose | Why Recommended | Confidence |
|------------|---------|---------|-----------------|------------|
| Vapor | 4.x (verify: may be 5.x by now) | Server-side Swift framework | Full-stack Swift means shared models between client and server. Type-safe routing, async/await native, built-in WebSocket/SSE support. Largest server-side Swift ecosystem. Deploys to any Linux VPS or container platform. | MEDIUM |
| SwiftSoup | ~2.7 | HTML parsing/scraping | Swift port of Java's Jsoup. Parses StatBroadcast HTML pages into structured data. CSS selector queries, DOM traversal. The standard choice for server-side Swift HTML scraping. | MEDIUM |
| PostgreSQL (via Fluent ORM) | 16.x | Primary database | Fluent is Vapor's ORM — supports PostgreSQL natively. Stores scraped game data, team rosters, historical scores. Postgres handles concurrent reads from multiple app clients without breaking a sweat. JSONB columns for flexible stat storage. | MEDIUM |
| Redis (via Vapor Redis) | 7.x | Caching + pub/sub | Cache hot scoreboard data (< 30s TTL during live games). Redis pub/sub can fan out score updates to SSE connections. Keeps database load manageable during peak game times. | MEDIUM |
| Queues (via Vapor Queues + Redis driver) | Built-in Vapor package | Job scheduling | Scheduled scraping jobs (every 30s during live games, every 15min otherwise). Retry logic for failed scrapes. Separate scrape workers from API request handlers. | MEDIUM |
| APNs (via Vapor APNs library) | ~4.x | Server-side push | `vapor/apns` package sends push notifications directly to Apple's APNs HTTP/2 endpoint. JWT-based auth. No Firebase middleman. | MEDIUM |

### Server — Infrastructure

| Technology | Purpose | Why Recommended | Confidence |
|------------|---------|-----------------|------------|
| Docker | Containerization | Vapor deploys as a Docker container. Consistent dev/prod environments. Most hosting platforms support Docker natively. | HIGH |
| Railway or Fly.io | Hosting | Both support Docker containers with persistent PostgreSQL and Redis add-ons. Railway has simpler DX for solo developers. Fly.io has edge deployment for lower latency. Either works; pick based on pricing preference. | MEDIUM |
| GitHub Actions | CI/CD | Automate: run tests, build Docker image, deploy to Railway/Fly. Free tier covers solo dev needs. | HIGH |

### Development Tools

| Tool | Purpose | Notes | Confidence |
|------|---------|-------|------------|
| Xcode 26 | iOS build/debug/deploy | Required for Liquid Glass previews, provisioning, TestFlight, device testing. | HIGH |
| Cursor + Claude | AI-assisted coding | Per UI-guidelines.md research: top-rated for SwiftUI vibe coding. Feed WWDC transcripts and LiquidGlassReference for context. | HIGH |
| Claude Code (CLI) | Multi-file refactoring | Large-scale changes across server and client packages. | HIGH |
| Instruments | Performance profiling | Liquid Glass effects are GPU-intensive. Profile on-device before TestFlight. | HIGH |
| Icon Composer | App icon creation | Apple's tool for Liquid Glass-compatible icons (light/dark/tinted/clear variants). | HIGH |
| Charles Proxy or Proxyman | Network debugging | Inspect scraping responses and API traffic during development. | MEDIUM |

---

## Installation

### iOS Client (Xcode Project)

```
Swift Package Dependencies (added via Xcode > File > Add Package):

- swift-collections: https://github.com/apple/swift-collections (if needed)

No other third-party packages required for v1.
The client is intentionally dependency-light — SwiftUI, SwiftData, URLSession,
and Foundation handle everything.
```

### Server (Vapor Project)

```bash
# Create new Vapor project
brew install vapor
vapor new BarDownServer --template api

# Package.swift dependencies (Vapor project):
# .package(url: "https://github.com/vapor/vapor.git", from: "4.0.0"),
# .package(url: "https://github.com/vapor/fluent.git", from: "4.0.0"),
# .package(url: "https://github.com/vapor/fluent-postgres-driver.git", from: "2.0.0"),
# .package(url: "https://github.com/vapor/redis.git", from: "4.0.0"),
# .package(url: "https://github.com/vapor/queues-redis-driver.git", from: "1.0.0"),
# .package(url: "https://github.com/vapor/apns.git", from: "4.0.0"),
# .package(url: "https://github.com/scinfu/SwiftSoup.git", from: "2.6.0"),

swift build
```

---

## Alternatives Considered

| Category | Recommended | Alternative | Why Not Alternative |
|----------|-------------|-------------|---------------------|
| Server framework | Vapor (Swift) | Firebase (BaaS) | Firebase locks you into Google's ecosystem. No custom scraping logic — you'd still need a separate server for scraping. Cloud Functions cold starts add latency. Vapor lets you share Swift models between client and server. |
| Server framework | Vapor (Swift) | Node.js (Express/Fastify) | Works fine technically, but loses the shared-model advantage. Two languages means two mental contexts. For a solo dev doing full-stack Swift, Vapor is more cohesive. |
| Server framework | Vapor (Swift) | Supabase | Good for CRUD apps, but scraping and scheduled jobs need custom server logic anyway. You'd end up running Supabase + a separate scraper service. Vapor consolidates everything. |
| Database | PostgreSQL | SQLite (server-side) | SQLite can't handle concurrent reads from multiple app clients efficiently. PostgreSQL is built for this. |
| Database | PostgreSQL | MongoDB | Relational data (teams have players, games have stats) maps naturally to relational tables. MongoDB's flexibility isn't needed and its query patterns are worse for the joins this app requires. |
| Real-time | SSE | WebSockets | WebSockets are bidirectional — the client never sends score data back. SSE is simpler, works over standard HTTP, reconnects automatically, and is sufficient for server-to-client streaming. |
| Real-time | SSE | Polling every N seconds | Wastes battery and bandwidth. SSE holds one connection open and pushes only when data changes. Better UX, less server load. |
| Push notifications | Direct APNs | Firebase Cloud Messaging | FCM adds a dependency on Google's SDK and servers for a single-platform iOS app. Direct APNs via Vapor's library is simpler, has lower latency, and keeps the stack pure Swift. |
| Local persistence | SwiftData | Core Data | SwiftData is the modern replacement with macro-based syntax. Less boilerplate. Better SwiftUI integration via `@Query`. Core Data still works but is legacy path. |
| Local persistence | SwiftData | Realm | Third-party dependency for something Apple provides natively. Realm adds binary size and potential compatibility issues on new OS releases. |
| HTML parsing | SwiftSoup | Puppeteer/Playwright (headless browser) | StatBroadcast pages are server-rendered HTML, not JavaScript SPAs. No headless browser needed — raw HTML parsing is faster, lighter, and cheaper to host. |
| Hosting | Railway/Fly.io | AWS (EC2/ECS) | Overkill for a solo dev project. More configuration, more cost, more ops burden. Railway/Fly abstract the infra so you focus on code. Scale to AWS later if needed. |

---

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| UIKit | Liquid Glass APIs are SwiftUI-first. UIKit adds bridging complexity (`UIViewRepresentable`) for zero benefit in a scores app. PROJECT.md mandates SwiftUI-only. | SwiftUI |
| React Native / Flutter | Cannot access Liquid Glass APIs. Apple rejects many wrapped apps. The entire design language requires native SwiftUI. | Native SwiftUI |
| Alamofire | Unnecessary abstraction over `URLSession` in 2026. Native async/await networking is cleaner and has zero dependency risk on new OS releases. | Foundation URLSession |
| SwiftyJSON | Superseded by native `Codable`. Adds dependency for something the language handles natively. | Swift Codable |
| CocoaPods | Maintenance mode. SPM is Apple's supported dependency manager. CocoaPods causes frequent Xcode project merge conflicts. | Swift Package Manager |
| Firebase Realtime Database / Firestore | Requires Google SDK (binary size bloat). No custom scraping. Vendor lock-in. You need server-side scraping logic regardless. | Vapor + PostgreSQL |
| Combine (for new code) | Swift Concurrency (async/await, AsyncSequence) replaces Combine's role for new projects. Combine still works but is no longer the recommended reactive pattern for SwiftUI. | async/await, AsyncSequence, @Observable |
| GRPC-Swift | Overkill for a mobile app consuming a REST/SSE API. Adds proto compilation step and complexity. REST + SSE is simpler and sufficient. | REST API + SSE |
| Realm | Third-party persistence when Apple provides SwiftData natively. Extra binary size, potential OS compatibility issues. | SwiftData |

---

## Stack Patterns

**If StatBroadcast pages are JavaScript-rendered (SPA):**
- Add a headless browser scraping step (Playwright via a Node.js sidecar or Python service)
- Confidence: LOW that this is needed — initial research suggests StatBroadcast uses server-rendered HTML
- Validate by fetching a page with `curl` and checking if game data is present in raw HTML

**If real-time latency matters more than simplicity:**
- Switch from SSE to WebSockets for bidirectional communication
- Use Vapor's built-in WebSocket support
- Only needed if you add features where client sends data back (e.g., live reactions)

**If the scraping load outgrows a single server:**
- Separate the scraper into its own service (same Vapor codebase, different deploy target)
- Scale scraper workers independently from API servers
- Redis pub/sub decouples the two

**If you need analytics later:**
- PostHog (self-hosted or cloud) for product analytics
- TelemetryDeck for privacy-focused Swift analytics (no Google Analytics)

---

## Version Compatibility

| Package | Compatible With | Notes | Confidence |
|---------|-----------------|-------|------------|
| Vapor 4.x | Swift 5.9+ / Swift 6.x | Verify Vapor 5.x release status — may have shipped by now with breaking changes | LOW |
| Fluent 4.x | Vapor 4.x | Tightly coupled — versions must match Vapor major version | MEDIUM |
| SwiftSoup ~2.7 | Swift 5.7+ | Stable, minimal API surface, unlikely to break | MEDIUM |
| SwiftData | iOS 17+ (available), iOS 26 (target) | Using iOS 26 minimum means full SwiftData availability guaranteed | HIGH |
| swift-collections 1.1 | Swift 5.9+ | Apple-maintained, stable | HIGH |

**Critical validation needed:**
- Check if Vapor 5.0 has shipped. If yes, use Vapor 5 — it likely has Swift 6 strict concurrency support built-in.
- Verify `vapor/apns` package version compatibility with latest Vapor.
- Confirm SwiftSoup works on Linux (for server deployment) — it should, but verify.

---

## Shared Model Strategy

A key advantage of the all-Swift stack: define data models once, use on both client and server.

```
BarDown/
  Shared/                    # Swift Package used by both client and server
    Sources/
      Models/
        Game.swift           # Game, Team, Player, BoxScore models
        Conference.swift     # Conference enum
        StatLine.swift       # Player stat lines
      DTOs/
        ScoreboardResponse.swift
        GameDetailResponse.swift
  BarDownApp/                # iOS client (Xcode project)
    Package.swift            # depends on Shared
  BarDownServer/             # Vapor server
    Package.swift            # depends on Shared
```

This eliminates JSON mapping mismatches between client and server. Both sides decode/encode the same types. Changes to the API contract are caught at compile time.

---

## Sources

- `/Users/darrenbrelesky/Documents/claude-code/BarDown/UI-guidelines.md` — Compiled Feb 2026 from Apple docs, WWDC sessions, community references. HIGH confidence for Liquid Glass and SwiftUI guidance.
- `/Users/darrenbrelesky/Documents/claude-code/BarDown/.planning/PROJECT.md` — Project requirements and constraints. HIGH confidence.
- Training data (cutoff May 2025) — MEDIUM confidence for Vapor, SwiftSoup, infrastructure recommendations. Versions may have advanced.
- Apple Developer Documentation (referenced in UI-guidelines.md) — HIGH confidence for SwiftUI, APNs, SwiftData, BackgroundTasks APIs.

**Verification needed (no web access available):**
- [ ] Vapor latest version (4.x vs 5.x) — check https://github.com/vapor/vapor/releases
- [ ] SwiftSoup latest version — check https://github.com/scinfu/SwiftSoup/releases
- [ ] vapor/apns package latest version — check https://github.com/vapor/apns/releases
- [ ] Railway vs Fly.io current pricing for Postgres + Redis
- [ ] Confirm StatBroadcast pages are server-rendered (curl test)

---
*Stack research for: BarDown — Native iOS D1 Lacrosse Scores App*
*Researched: 2026-02-24*
