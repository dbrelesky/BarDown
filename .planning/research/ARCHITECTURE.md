# Architecture Research

**Domain:** Real-time college lacrosse scores — native iOS app with cloud scraping backend
**Researched:** 2026-02-24
**Confidence:** MEDIUM (training data only — WebSearch and WebFetch unavailable; patterns are well-established but specific API details should be validated)

## Standard Architecture

### System Overview

```
┌──────────────────────────────────────────────────────────────────┐
│                       PRESENTATION LAYER (iOS)                    │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐  ┌───────────┐  │
│  │ Scoreboard │  │ Game Detail│  │  Rankings  │  │Leaderboard│  │
│  │   View     │  │    View    │  │    View    │  │   View    │  │
│  └─────┬──────┘  └─────┬──────┘  └─────┬──────┘  └─────┬─────┘  │
│        │               │               │               │         │
│  ┌─────┴───────────────┴───────────────┴───────────────┴─────┐   │
│  │              ViewModels (@Observable classes)              │   │
│  └─────────────────────────┬─────────────────────────────────┘   │
│                            │                                      │
│  ┌─────────────────────────┴─────────────────────────────────┐   │
│  │              Services / Repositories Layer                 │   │
│  │   ┌──────────┐  ┌──────────────┐  ┌───────────────────┐   │   │
│  │   │ APIClient│  │ CacheManager │  │NotificationService│   │   │
│  │   └──────────┘  └──────────────┘  └───────────────────┘   │   │
│  └───────────────────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────────────────┘
                             │ HTTPS (REST JSON)
                             ▼
┌──────────────────────────────────────────────────────────────────┐
│                       CLOUD BACKEND                               │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │                      API Gateway                           │  │
│  │  /scores  /games/:id  /rankings  /leaderboards  /schedule  │  │
│  └──────────────────────────┬─────────────────────────────────┘  │
│                             │                                     │
│  ┌──────────────────────────┴─────────────────────────────────┐  │
│  │                    Application Logic                        │  │
│  │  ┌─────────────┐  ┌───────────────┐  ┌──────────────────┐  │  │
│  │  │Score Differ  │  │Push Evaluator │  │ Data Normalizer  │  │  │
│  │  │(change detect)│ │(trigger rules)│  │(clean + store)   │  │  │
│  │  └─────────────┘  └───────────────┘  └──────────────────┘  │  │
│  └────────────────────────────────────────────────────────────┘  │
│                             │                                     │
│  ┌──────────────────────────┴─────────────────────────────────┐  │
│  │                     Data Layer                              │  │
│  │  ┌──────────┐  ┌──────────────┐  ┌──────────────────────┐  │  │
│  │  │ Database │  │  Job Queue   │  │  Push Token Store    │  │  │
│  │  │(Postgres)│  │(cron/schedule)│  │(device → team map)  │  │  │
│  │  └──────────┘  └──────────────┘  └──────────────────────┘  │  │
│  └────────────────────────────────────────────────────────────┘  │
│                             │                                     │
│  ┌──────────────────────────┴─────────────────────────────────┐  │
│  │                   Scraping Pipeline                         │  │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────────┐  │  │
│  │  │ StatBroadcast│  │  NCAA API    │  │  HTML Parser     │  │  │
│  │  │  Scraper     │  │  Client      │  │  (SwiftSoup/etc)   │  │  │
│  │  └──────────────┘  └──────────────┘  └──────────────────┘  │  │
│  └────────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────┘
                             │
                             ▼
┌──────────────────────────────────────────────────────────────────┐
│                    EXTERNAL DATA SOURCES                          │
│  ┌──────────────────┐  ┌──────────────────────────────────────┐  │
│  │  StatBroadcast   │  │  NCAA (supplementary schedules/ranks)│  │
│  │  (HTML scraping) │  │  (REST/JSON if available)            │  │
│  └──────────────────┘  └──────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────┘
```

### Component Responsibilities

| Component | Responsibility | Communicates With |
|-----------|---------------|-------------------|
| **SwiftUI Views** | Render UI, handle user gestures, display data | ViewModels (observe state) |
| **ViewModels** | Hold screen state, coordinate data requests, transform models for display | Services, Views (publish state) |
| **APIClient** | Single HTTPS client to backend API, request/response coding, auth if needed | Backend API Gateway |
| **CacheManager** | Local persistence (SwiftData or in-memory) for offline/fast-load | APIClient (populates), ViewModels (reads) |
| **NotificationService** | Register device token with APNs, forward token to backend, handle incoming pushes | APNs, Backend push store |
| **API Gateway** | Route incoming REST requests, rate limiting, response caching | Application Logic |
| **Score Differ** | Compare new scrape results to stored data, detect score changes and game state transitions | Database, Push Evaluator |
| **Push Evaluator** | Decide which users to notify based on favorites and alert rules | Score Differ, APNs, Push Token Store |
| **Data Normalizer** | Clean raw scraped HTML/JSON into canonical data models | Scrapers, Database |
| **Scraping Pipeline** | Fetch HTML from StatBroadcast on schedule, parse into structured data | StatBroadcast, NCAA API, Data Normalizer |
| **Database** | Persistent store for games, scores, teams, players, rankings | All backend components |
| **Job Queue / Scheduler** | Trigger scraping at intervals (every 30s during live games, hourly otherwise) | Scraping Pipeline |

## Recommended Project Structure

### iOS App (Xcode Project)

```
BarDown/
├── App/
│   ├── BarDownApp.swift          # @main entry, scene setup
│   └── AppState.swift            # App-wide shared state (favorites, settings)
├── Models/
│   ├── Game.swift                # Game model (scores, status, teams)
│   ├── Team.swift                # Team model (name, conference, logo URL)
│   ├── Player.swift              # Player stat line
│   ├── PlayByPlay.swift          # Play-by-play event
│   ├── Ranking.swift             # Poll ranking entry
│   └── LeaderboardEntry.swift    # Stat leader entry
├── Services/
│   ├── APIClient.swift           # Network layer to backend
│   ├── CacheManager.swift        # Local persistence
│   ├── NotificationService.swift # APNs registration + handling
│   └── FavoritesManager.swift    # UserDefaults/SwiftData for favorites
├── ViewModels/
│   ├── ScoreboardViewModel.swift # Today's games, filtering, polling
│   ├── GameDetailViewModel.swift # Single game box score, play-by-play
│   ├── RankingsViewModel.swift   # Weekly poll data
│   └── LeaderboardViewModel.swift# Stat leaders
├── Views/
│   ├── Scoreboard/
│   │   ├── ScoreboardView.swift  # Main scoreboard screen
│   │   ├── GameCardView.swift    # Individual game row/card
│   │   └── DatePickerBar.swift   # Horizontal date picker
│   ├── GameDetail/
│   │   ├── GameDetailView.swift  # Full game detail container
│   │   ├── BoxScoreView.swift    # Quarter scores, team stats
│   │   ├── PlayByPlayView.swift  # Event feed
│   │   └── PlayerStatsView.swift # Individual stat lines
│   ├── Rankings/
│   │   └── RankingsView.swift    # Poll tracker
│   ├── Leaderboard/
│   │   └── LeaderboardView.swift # Stat leaders
│   ├── Favorites/
│   │   └── OnboardingView.swift  # Team selection
│   └── Shared/
│       ├── TeamLogoView.swift    # Cached async logo image
│       ├── LiveIndicator.swift   # Pulsing "LIVE" badge
│       └── GlassModifiers.swift  # Liquid Glass convenience modifiers
├── Extensions/
│   └── Date+Helpers.swift
└── Resources/
    └── Assets.xcassets
```

### Cloud Backend (Swift/Vapor 4)

```
Sources/
├── App/
│   ├── entrypoint.swift              # @main Vapor entry point
│   ├── configure.swift               # DB config, migrations, middleware
│   ├── routes.swift                  # Route registration
│   ├── Controllers/
│   │   ├── GameController.swift      # /api/v1/games endpoints
│   │   └── TeamController.swift      # /api/v1/teams endpoints
│   ├── DTOs/
│   │   ├── GameResponse.swift        # Clean JSON response shapes
│   │   ├── BoxScoreResponse.swift
│   │   ├── ScheduleResponse.swift
│   │   └── TeamBrief.swift
│   ├── Models/
│   │   ├── Conference.swift          # Fluent model
│   │   ├── Team.swift
│   │   ├── Player.swift
│   │   ├── Game.swift
│   │   ├── QuarterScore.swift
│   │   ├── GameStats.swift
│   │   └── PlayerGameStats.swift
│   ├── Migrations/
│   │   ├── CreateConference.swift
│   │   ├── CreateTeam.swift
│   │   ├── CreateGame.swift
│   │   └── SeedConferences.swift
│   ├── Scraping/
│   │   ├── StatBroadcast/
│   │   │   ├── ScoreboardScraper.swift   # Parse scoreboard HTML via SwiftSoup
│   │   │   ├── GameDetailScraper.swift   # Parse in-game detail HTML
│   │   │   └── HTMLParser.swift          # HTML → structured data (SwiftSoup)
│   │   └── NCAA/
│   │       └── NCAAClient.swift          # NCAA API calls
│   └── Jobs/
│       ├── ScrapeScheduler.swift         # VaporCron job orchestration
│       ├── ScrapeScoreboard.swift        # Scheduled: scrape all live scores
│       └── ScrapeGameDetail.swift        # Scheduled: scrape active game details
├── Package.swift
├── Dockerfile
└── docker-compose.yml
```

### Structure Rationale

- **iOS — Feature-grouped Views/:** Each screen gets its own folder. Keeps related views together rather than scattering by file type. Shared/ holds truly reusable components.
- **iOS — Separate ViewModels/:** Keeps business logic testable and out of Views. One ViewModel per screen is the standard pattern.
- **iOS — Services/:** Thin layer wrapping external concerns (network, storage, notifications). ViewModels depend on protocols for testability.
- **Backend — scraping/ separated from api/:** Scraping runs on a schedule independent of API requests. Clean boundary makes it possible to swap data sources without touching the API layer.
- **Backend — notifications/ as its own module:** Push logic is triggered by scraping results, not by API requests. Separate module keeps the concern isolated.

## Architectural Patterns

### Pattern 1: MVVM with @Observable (iOS)

**What:** Each screen has a View observing an `@Observable` ViewModel class. The ViewModel holds published state and exposes methods. Views are purely declarative renderers.
**When to use:** Every screen in the app. This is the standard SwiftUI pattern as of iOS 17+.
**Trade-offs:** Simple and well-supported. Can lead to "god ViewModels" if not disciplined about splitting responsibilities into Services.

**Example:**
```swift
@Observable
final class ScoreboardViewModel {
    var games: [Game] = []
    var selectedDate: Date = .now
    var isLoading = false
    var filter: GameFilter = .favorites

    private let apiClient: APIClientProtocol

    init(apiClient: APIClientProtocol) {
        self.apiClient = apiClient
    }

    func loadGames() async {
        isLoading = true
        defer { isLoading = false }
        games = (try? await apiClient.fetchScores(date: selectedDate)) ?? []
    }
}
```

### Pattern 2: Polling with Timer for Live Scores (iOS)

**What:** During live games, the app polls the backend API at a fixed interval (every 15-30 seconds). When no games are live, polling stops or drops to a much longer interval. The ViewModel manages the timer lifecycle.
**When to use:** Live scoreboard screen when games are in progress.
**Trade-offs:** Simple to implement, no WebSocket complexity. Uses slightly more battery than push-only, but polling intervals of 15-30s are acceptable. Far simpler than maintaining persistent socket connections for a v1.

**Example:**
```swift
@Observable
final class ScoreboardViewModel {
    private var pollTask: Task<Void, Never>?

    func startPolling() {
        pollTask = Task {
            while !Task.isCancelled {
                await loadGames()
                try? await Task.sleep(for: .seconds(hasLiveGames ? 15 : 300))
            }
        }
    }

    func stopPolling() {
        pollTask?.cancel()
    }
}
```

### Pattern 3: Server-Side Score Diffing for Push Notifications

**What:** The backend scrapes scores on a fast interval. After each scrape, a "differ" compares new data against the previously stored state. When a meaningful change is detected (score change, game ended, upset conditions), the Push Evaluator queries which users have favorited the relevant teams and sends APNs notifications.
**When to use:** All push notification triggers. This keeps push logic entirely server-side, so the app never needs to be running to receive alerts.
**Trade-offs:** Requires the backend to maintain state (last known score per game). Adds complexity to the scraping pipeline but is the only way to do push reliably.

### Pattern 4: Backend-Owned Scraping (Not Client-Side)

**What:** All web scraping happens on the backend. The iOS app never touches StatBroadcast directly. The app only talks to our own REST API, which returns clean JSON.
**When to use:** Always. This is a non-negotiable architectural boundary.
**Trade-offs:** Adds backend infrastructure cost. But it is essential because: (1) scraping from mobile devices is fragile and battery-killing, (2) StatBroadcast could block mobile IP ranges, (3) push notifications require server-side knowledge of score changes, (4) a single backend scraper is far easier to maintain than parsing HTML in Swift.

## Data Flow

### Live Score Update Flow

```
[StatBroadcast HTML page]
    │ (every 30s during live games)
    ▼
[Scraping Pipeline] ── parse HTML ──▶ [Data Normalizer]
    │                                       │
    │                                       ▼
    │                                [Database UPDATE]
    │                                       │
    ▼                                       ▼
[Score Differ] ◀── compare old vs new ── [Database READ]
    │
    ├── score changed? ──▶ [Push Evaluator] ──▶ [APNs] ──▶ [User's iPhone]
    │
    ▼
[API endpoint returns fresh data on next poll]
    │
    ▼
[iOS APIClient] ──▶ [ViewModel] ──▶ [SwiftUI View re-renders]
```

### App Launch Flow

```
[User opens app]
    │
    ▼
[BarDownApp.swift] ── check notification permissions ──▶ [NotificationService]
    │                                                         │
    │                                                    register token
    │                                                    with backend
    ▼
[ScoreboardView appears]
    │
    ▼
[ScoreboardViewModel.loadGames()]
    │
    ▼
[APIClient.fetchScores(date: .today)]
    │
    ├── Cache hit? ──▶ show cached data immediately
    │
    ▼
[HTTPS GET /scores?date=2026-02-24]
    │
    ▼
[Backend returns JSON array of Game objects]
    │
    ▼
[ViewModel updates games array]
    │
    ▼
[SwiftUI re-renders scoreboard]
    │
    ▼
[If live games detected, start 15s polling timer]
```

### Push Notification Registration Flow

```
[App launch / onboarding]
    │
    ▼
[UNUserNotificationCenter.requestAuthorization()]
    │
    ▼
[UIApplication.registerForRemoteNotifications()]
    │
    ▼
[didRegisterForRemoteNotificationsWithDeviceToken]
    │
    ▼
[POST /devices { token: "abc123", favoriteTeams: ["duke", "virginia"] }]
    │
    ▼
[Backend stores token ↔ team mapping in Push Token Store]
```

### Key Data Flows

1. **Scrape-to-screen:** StatBroadcast HTML → Backend scraper → Normalized DB rows → REST API JSON → iOS APIClient → ViewModel → View. Total latency target: < 45 seconds from real-world event to screen update.
2. **Scrape-to-push:** StatBroadcast HTML → Backend scraper → Score Differ detects change → Push Evaluator matches user favorites → APNs delivery. Total latency target: < 60 seconds from real-world event to push notification.
3. **Favorites sync:** User selects favorites in app → stored locally (SwiftData/UserDefaults) AND sent to backend (POST /devices) → backend uses for push targeting. Local-first so the app works offline.

## Scaling Considerations

| Scale | Architecture Adjustments |
|-------|--------------------------|
| 0-1k users (TestFlight/launch) | Single server instance, SQLite or small Postgres. Scraping + API on same process. No CDN needed. Cost: ~$5-15/month on Railway/Fly.io. |
| 1k-10k users | Add response caching (Redis or in-memory TTL). Separate scraping worker from API server. CDN for team logo images. Cost: ~$25-50/month. |
| 10k-100k users | Horizontal API scaling behind load balancer. Dedicated scraping workers. APNs batch sending. Database connection pooling. Cost: ~$100-300/month. |

### Scaling Priorities

1. **First bottleneck — API response time during peak game hours:** Every user polls simultaneously during live games. Aggressive HTTP caching (Cache-Control headers, CDN edge caching) solves this. Scores only change every 30s, so a 10-15s cache TTL loses almost nothing.
2. **Second bottleneck — Push notification fan-out:** Sending thousands of APNs requests when a popular team scores. Solve with batch/concurrent APNs HTTP/2 connections and a job queue (not inline with scraping).
3. **Third bottleneck — Scraping rate limits:** StatBroadcast may throttle if we scrape too aggressively. Solve by scraping the scoreboard page (all games at once) rather than individual game pages, and only scraping detail pages for active/live games.

## Anti-Patterns

### Anti-Pattern 1: Client-Side Scraping

**What people do:** Parse StatBroadcast HTML directly in the iOS app.
**Why it's wrong:** HTML structure changes break every deployed app instantly with no way to hotfix. Mobile scraping is slow, battery-draining, and IP-blockable. Impossible to do push notifications without a server.
**Do this instead:** All scraping on the backend. App consumes clean REST JSON. If StatBroadcast changes HTML structure, fix the backend scraper once and all clients instantly get correct data.

### Anti-Pattern 2: WebSocket for Live Scores in v1

**What people do:** Build a WebSocket server for real-time push of score updates to avoid polling.
**Why it's wrong:** Massive infrastructure complexity for marginal UX improvement. WebSocket connections are expensive to maintain, tricky with mobile network transitions (WiFi ↔ cellular), and require reconnection logic. For scores that change every few minutes, 15-30s polling is indistinguishable from "real-time."
**Do this instead:** HTTP polling at 15-30s intervals for live games. Revisit WebSocket/SSE only if user feedback demands sub-second latency (unlikely for lacrosse scores).

### Anti-Pattern 3: Monolithic ViewModel

**What people do:** Put all scoreboard logic, game detail logic, favorites logic, and notification handling into one giant ViewModel or App State object.
**Why it's wrong:** Becomes untestable, hard to reason about, recomputes too much state on changes.
**Do this instead:** One ViewModel per screen. Shared state (favorites, settings) lives in a small AppState @Observable passed via @Environment. Services are injected into ViewModels.

### Anti-Pattern 4: Scraping Every Game Page Individually

**What people do:** Hit StatBroadcast's individual game page for every active game on every scrape cycle.
**Why it's wrong:** N games = N HTTP requests per cycle. Gets rate-limited fast, wastes bandwidth, increases latency.
**Do this instead:** Scrape the scoreboard overview page first (one request, all games). Only scrape individual game detail pages for games that are currently live AND have been opened by a user recently (or for push notification detail).

### Anti-Pattern 5: Storing Scraped HTML in the Database

**What people do:** Store raw HTML blobs and parse them on API request.
**Why it's wrong:** Slow API responses, parsing errors leak to users, impossible to query structured data.
**Do this instead:** Parse HTML immediately in the scraping pipeline. Store only structured, normalized data (scores, stats, events as typed columns/rows).

## Integration Points

### External Services

| Service | Integration Pattern | Notes |
|---------|---------------------|-------|
| **StatBroadcast** | HTTP GET + HTML parsing (SwiftSoup/regex) | No official API. Parse the scoreboard and game detail pages. Respect rate limits. User-Agent should mimic a browser. |
| **NCAA API** | REST JSON client | Supplementary data for schedules and rankings. Endpoints may change without notice. |
| **APNs** | HTTP/2 POST to api.push.apple.com | Requires APNs auth key (.p8 file) from Apple Developer account. Use token-based auth (not certificate-based). |
| **Team Logos** | Static asset hosting or CDN | Scrape logo URLs from StatBroadcast/NCAA, cache on our CDN. Do not hotlink — download and re-host. |

### Internal Boundaries

| Boundary | Communication | Notes |
|----------|---------------|-------|
| iOS App ↔ Backend API | HTTPS REST (JSON) | App never touches scraped sources directly. Clean contract via API routes. |
| Scraping Pipeline ↔ Database | Direct DB writes | Scraper is a trusted internal component, writes directly. |
| Score Differ ↔ Push Evaluator | In-process function call or job queue message | During live games, this path is hot. Keep it fast — no HTTP overhead. |
| API Routes ↔ Database | Read-only queries | API layer only reads. Scraping pipeline owns writes. Prevents write contention. |
| Push Evaluator ↔ APNs | HTTP/2 outbound | Use connection pooling. APNs supports multiplexed streams on a single connection. |

## Build Order (Suggested)

Build order is driven by dependencies — each phase unlocks the next.

| Order | Component | Depends On | Unlocks |
|-------|-----------|------------|---------|
| 1 | **Data models (shared)** | Nothing | Everything else |
| 2 | **Backend scraping pipeline** | Data models | Database population, all API endpoints |
| 3 | **Database + schema** | Data models | API layer, push notifications |
| 4 | **Backend REST API** | Database with data | iOS app development |
| 5 | **iOS core views (Scoreboard, Game Detail)** | Backend API running | User-facing testing |
| 6 | **iOS polling + caching** | Core views | Live game experience |
| 7 | **Favorites system** | Core views, backend device endpoint | Push notification targeting |
| 8 | **Push notification pipeline** | Favorites, score differ, APNs setup | Alert experience |
| 9 | **Rankings + Leaderboards** | Backend API endpoints for those data | Feature completeness |
| 10 | **Polish (Liquid Glass, animations, onboarding)** | All features working | TestFlight readiness |

**Key dependency insight:** The backend scraping pipeline must work first because without real data flowing into the database, there is nothing for the API to serve and nothing for the iOS app to display. Build backend-first, iOS-second.

## Sources

- Apple Developer Documentation: SwiftUI data flow, @Observable macro, Observation framework (HIGH confidence — well-established patterns since iOS 17/WWDC 2023)
- Apple Developer Documentation: UserNotifications framework, APNs HTTP/2 provider API (HIGH confidence — stable API)
- StatBroadcast scoreboard URLs from PROJECT.md (HIGH confidence — provided by project owner)
- General industry patterns for sports score app architecture (MEDIUM confidence — training data, not verified against live sources)
- Polling vs WebSocket trade-offs for mobile apps (MEDIUM confidence — well-established engineering consensus but not verified against 2026 sources)

**Note:** WebSearch and WebFetch were unavailable during this research session. All findings are based on training data. Core SwiftUI and APNs patterns are stable and well-established (HIGH confidence), but specific library versions and StatBroadcast HTML structure should be validated during implementation.

---
*Architecture research for: BarDown — real-time college lacrosse scores*
*Researched: 2026-02-24*
