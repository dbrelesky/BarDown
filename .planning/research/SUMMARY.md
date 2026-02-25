# Project Research Summary

**Project:** BarDown — Native iOS D1 Lacrosse Scores App
**Domain:** Real-time college sports scores — native iOS app with cloud scraping backend
**Researched:** 2026-02-24
**Confidence:** MEDIUM

## Executive Summary

BarDown is a native iOS sports scores app targeting a clear gap in the market: ESPN buries men's D1 lacrosse four taps deep and shows minimal stats; no dedicated mobile lacrosse app exists with reliable live scores, full box scores, and a premium iOS-native design. The recommended build approach is a full-stack Swift monorepo — SwiftUI on iOS (targeting iOS 26 with Liquid Glass) backed by a Vapor server that handles all web scraping from StatBroadcast and serves clean REST JSON to the client. This shared-Swift strategy allows data models to be defined once and reused on both sides, catching API contract mismatches at compile time rather than at runtime.

The critical architectural insight is that the backend scraping pipeline must be built first and validated before any iOS UI work begins. StatBroadcast is not a documented API — it is a rendered HTML page that can change without notice, may be JavaScript-rendered (requiring direct XHR endpoint discovery), and can rate-limit or block aggressive scrapers. A data availability audit across multiple conferences must happen in the first phase; building beautiful screens against idealized mock data and then discovering the real data doesn't match is the single most costly mistake in this type of app. Everything else — the scoreboard, game detail, favorites, notifications — is a display layer on top of this data foundation.

The primary risks are data fragility (StatBroadcast HTML instability and scraping rate limits), Liquid Glass misuse (applying glass effects to content rather than navigation chrome, which iOS 26 HIG explicitly prohibits), and scope creep (push notifications, play-by-play, and Dynamic Island are high-value but high-complexity features that require mature infrastructure before implementation). Mitigation is straightforward: build a resilient scraper abstraction first, establish a GlassKit design module before building any screens, and defer P2/P3 features until the core loop is validated with real users.

## Key Findings

### Recommended Stack

The app is built on two Swift packages sharing a common `Shared/` models package: the iOS client (SwiftUI, SwiftData, URLSession, BackgroundTasks, APNs) and the Vapor backend server (Fluent + PostgreSQL, Redis, Queues, SwiftSoup for HTML parsing). The client is intentionally dependency-light — no Alamofire, no Combine, no Firebase. The backend handles all scraping, score diffing, and push notification fan-out.

**Core technologies:**
- SwiftUI (iOS 26+): UI framework — project mandate; Liquid Glass APIs are SwiftUI-first, no UIKit needed
- Vapor 4.x (verify 5.x): Server framework — shared Swift models between client and server; type-safe routing; built-in SSE/WebSocket support
- SwiftSoup ~2.7: HTML parsing — Swift-native, server-side, parses StatBroadcast pages into structured data
- PostgreSQL 16.x via Fluent: Primary DB — handles concurrent reads from multiple clients; JSONB for flexible stat storage
- Redis 7.x: Caching + pub/sub — hot scoreboard cache (< 30s TTL during games), fan-out to SSE connections
- APNs (direct, no Firebase): Push notifications — single-platform iOS app; direct APNs via `vapor/apns` is simpler and lower latency
- SwiftData: Local persistence — native replacement for Core Data; `@Model` macros integrate with SwiftUI `@Query`
- Docker + Railway or Fly.io: Hosting — both support Docker containers with Postgres/Redis add-ons; Railway has simpler DX for solo dev

**Version validation needed:** Confirm whether Vapor 5.x has shipped (breaking changes from 4.x possible). Confirm SwiftSoup Linux compatibility for server deployment. Verify `vapor/apns` current version.

### Expected Features

The competitive opportunity is depth over breadth: do men's D1 lacrosse better than any general-purpose sports app. ESPN's lacrosse path is 4 taps; BarDown's is zero. The must-haves are the data layer (scraping pipeline, REST API) and the core display loop (scoreboard, game detail, favorites, date navigation).

**Must have (table stakes — P1 for TestFlight beta):**
- Live scoreboard — the entire reason the app exists; open app, see today's scores
- Game detail / box score — lacrosse-specific stats ESPN doesn't surface (faceoffs, GBs, save %)
- Date navigation — horizontal date picker for yesterday/tomorrow
- Team favorites with onboarding — persist to SwiftData/UserDefaults; pin to top of scoreboard
- Conference filtering — reduce noise on busy Saturdays (30+ games)
- Team schedules — filtered view of season schedule per team
- Standings / poll rankings — weekly Inside Lacrosse/USILA poll with movement indicators
- School logos — visual hero; without logos the app feels generic
- Cloud backend + scraping pipeline — the foundation that enables everything else
- Dark mode as default, light mode supported

**Should have (differentiators — P2, after core validation):**
- Push notifications for favorites — game start, final score; critical for retention
- Live play-by-play feed — real-time event stream; only available if StatBroadcast data supports it
- Player leaderboards — conference and national stat leaders; mobile-native gap in the market
- Widget support (WidgetKit) — next game / live score on Lock Screen and Home Screen
- Game countdown / pre-game cards — useful when no games are live

**Defer (v2+):**
- Live Activity / Dynamic Island — requires mature push infrastructure; highest polish ceiling
- Upset alerts — smart notifications; requires ranking data + push + monitoring; high value but high complexity
- Player season profiles — season stat aggregation across all games; significant backend work
- Women's lacrosse — only after men's D1 architecture is stable and proven

**Anti-features (explicitly not building):** News/editorial content, social features, video highlights, betting lines, fantasy lacrosse, user accounts/login, banner ads in v1.

### Architecture Approach

The architecture is a layered system with a hard boundary between the iOS client and the backend scraping pipeline. The iOS app never touches StatBroadcast directly — it only consumes clean REST JSON from the Vapor API. On the iOS side, the pattern is MVVM with `@Observable` ViewModels (one per screen), thin Services for network/storage/notifications, and SwiftUI Views as pure declarative renderers. On the backend, scraping runs on a scheduled job queue (every 30s during live games, every 15min otherwise), feeds through a Score Differ that detects changes, and triggers push notifications via a Push Evaluator that matches score changes to user favorites.

**Major components:**
1. **Scraping Pipeline** — fetches StatBroadcast HTML on schedule, parses via SwiftSoup, normalizes into structured DB rows; the critical-path foundation
2. **Score Differ + Push Evaluator** — compares old/new scrape state; triggers APNs for meaningful events (start, final, upset)
3. **REST API Gateway** — serves clean JSON to iOS clients; read-only from DB; response-cached via Redis (10-15s TTL)
4. **iOS ViewModel layer** — holds screen state, drives 15-30s polling during live games, stops polling when no games are live
5. **CacheManager (iOS)** — SwiftData local persistence for offline fallback; show cached data with "last updated" badge when network is unavailable

**Build order:** Data models → Backend scraping pipeline → Database schema → Backend REST API → iOS core views → iOS polling + caching → Favorites → Push notifications → Rankings + leaderboards → Polish.

### Critical Pitfalls

1. **StatBroadcast HTML instability** — build a scraping abstraction layer with per-conference parser adapters from day one; store raw HTML snapshots for replay/debugging; build a health-check endpoint; never hardcode CSS selectors directly in business logic
2. **Building UI before validating data availability** — sprint zero must be a data audit: scrape 10+ real games across 3+ conferences and catalog exactly which fields exist; map every UI element to a verified data source; design for graceful degradation ("N/A" not crashes)
3. **JavaScript-rendered content** — use browser DevTools on live StatBroadcast pages to identify underlying XHR/fetch endpoints before writing any parser; the actual data likely comes from a direct JSON endpoint, not from the rendered HTML
4. **Liquid Glass on content layers** — glass belongs only on navigation chrome (tab bar, toolbar, sheets); build a `GlassKit` module that centralizes all `.glassEffect()` calls before building any screens; more than 5-6 `.glassEffect()` calls in the codebase is a warning sign
5. **Push notification architecture doesn't scale** — use push only for high-signal events (game start, final, upsets), not every goal; for in-app live updates use polling/SSE; batch and deduplicate before sending to APNs; design the architecture boundary in Phase 1 even though implementation is Phase 3

## Implications for Roadmap

Based on the dependency chain identified in both ARCHITECTURE.md and FEATURES.md, the roadmap must be backend-first, iOS-second. Nothing in the app works without real data flowing through the scraping pipeline. The data audit is the single highest-leverage first task.

### Phase 1: Data Foundation and Backend API

**Rationale:** The scraping pipeline is the critical dependency for every feature in the app. StatBroadcast's reliability and data structure must be validated with real data before any UI work begins. Building the API contract before the iOS app ensures the client has something real to integrate against.
**Delivers:** Working data pipeline (StatBroadcast → PostgreSQL → REST API), validated data availability matrix across all D1 conferences, shared Swift data models, deployable backend
**Addresses:** Live scoreboard data, game detail data, standings data, team/schedule data
**Avoids:** Data model mismatch pitfall, JS-rendered content pitfall, rate limiting pitfall, building UI against unvalidated data

### Phase 2: iOS App Shell and Core Screens

**Rationale:** With a working API returning real data, the core iOS screens can be built against actual responses. The design system (GlassKit) must be established before building any screens to prevent Liquid Glass misuse from spreading across the codebase.
**Delivers:** Scoreboard, game detail/box score, date navigation, conference filtering, team schedules, favorites onboarding — all with proper loading/error/empty states and offline caching
**Uses:** SwiftUI, SwiftData, URLSession + async/await, `@Observable` ViewModels, school logos
**Implements:** MVVM architecture, CacheManager, polling timer, GlassKit design module

### Phase 3: Standings, Rankings, and Feature Completeness

**Rationale:** Standings and rankings require a reliable data pipeline (Phase 1) and the core navigation shell (Phase 2). These complete the P1 TestFlight launch feature set.
**Delivers:** Weekly poll rankings with movement indicators, conference standings, pre-game cards, game countdown timers — the full v1 TestFlight-ready feature set
**Avoids:** Hardcoded poll data; rankings views must handle preseason/mid-season/postseason poll states

### Phase 4: Push Notifications and Retention Loop

**Rationale:** Push requires validated backend infrastructure (Phase 1) and a confirmed user base (TestFlight feedback). Building it earlier risks over-engineering for an unvalidated audience. The APNs architecture decision (high-signal events only, not every goal) must be made here.
**Delivers:** APNs integration, device token registration, push notification fan-out (game start, final score), user notification preferences
**Uses:** Vapor APNs library, Push Token Store, Score Differ (backend), UNUserNotificationCenter (iOS)
**Implements:** Push Evaluator, APNs batch sending, user preference management

### Phase 5: Live Play-by-Play and Player Leaderboards

**Rationale:** Play-by-play depends on StatBroadcast data availability being fully validated (requires Phase 1 findings). Player leaderboards require stat aggregation jobs running across all games. Both are high-value differentiators but should only be built after the core loop is stable.
**Delivers:** Real-time event feed in game detail view, national/conference stat leaderboards, player stat aggregation backend jobs
**Avoids:** Building play-by-play UI before confirming StatBroadcast exposes the data in a parseable form

### Phase 6: Widgets, Polish, and App Store Submission

**Rationale:** WidgetKit integration requires App Group setup and stable data contracts from all prior phases. Liquid Glass polish, onboarding refinement, and App Store assets are final-mile work.
**Delivers:** Lock Screen and Home Screen widgets, WidgetKit ViewController extension, App Store submission (metadata, screenshots, app icon via Icon Composer), TestFlight → App Store promotion
**Implements:** WidgetKit Timeline provider, App Group shared data container, Liquid Glass animations refinement

### Phase Ordering Rationale

- Backend must precede iOS because the iOS app has no data source without it — this is a hard dependency, not a preference
- Data audit must precede all UI design to prevent the single most costly pitfall: building screens against data that doesn't exist
- GlassKit module must precede any screen-building to prevent `.glassEffect()` misuse from spreading
- Push notifications must follow core app validation to avoid over-engineering for unproven user behavior
- Play-by-play is gated on StatBroadcast data validation — if that data isn't available, this feature is descoped without blocking the roadmap
- Widgets follow because they require App Group setup and stable data contracts across multiple app extensions

### Research Flags

Phases likely needing deeper research during planning:

- **Phase 1 (Data Foundation):** StatBroadcast HTML structure is unverified — requires hands-on DevTools investigation of live game pages to determine whether content is static HTML or JS-rendered, and to identify any direct XHR/JSON endpoints. This is the highest-priority validation task.
- **Phase 4 (Push Notifications):** APNs rate limit behavior and batch sending patterns under load require validation. Load test with a simulated 20-game Saturday before production launch.
- **Phase 5 (Play-by-Play):** Entirely contingent on StatBroadcast data availability for play-by-play events. May be descoped if data is not available in a parseable format.

Phases with standard patterns (skip research-phase):

- **Phase 2 (iOS Core):** MVVM with `@Observable`, SwiftData, URLSession async/await — well-documented Apple-standard patterns since iOS 17. No research needed.
- **Phase 3 (Rankings):** Standard data display pattern on top of existing API infrastructure. No novel architecture.
- **Phase 6 (Widgets/Polish):** WidgetKit is well-documented. App Store submission process is stable. No research needed.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | MEDIUM | Core Apple APIs (SwiftUI, SwiftData, APNs, BackgroundTasks) are HIGH confidence. Vapor version (4 vs 5) and exact package versions need verification — web search was unavailable during research. |
| Features | MEDIUM | Feature prioritization is based on well-established sports app patterns (ESPN, theScore, FotMob). StatBroadcast data availability for play-by-play is unverified and should be treated as LOW confidence until validated with live pages. |
| Architecture | MEDIUM-HIGH | Core patterns (MVVM, polling, server-side scraping, score diffing) are industry-standard and well-documented. StatBroadcast-specific HTML structure is unverified. |
| Pitfalls | HIGH | Pitfalls are drawn from Apple HIG (Liquid Glass), APNs documentation, and well-established web scraping engineering knowledge. The UI-guidelines.md source (compiled Feb 2026 from Apple WWDC25 sessions) gives the Liquid Glass pitfalls especially high confidence. |

**Overall confidence:** MEDIUM

### Gaps to Address

- **StatBroadcast page structure:** Must validate with a live game. Use browser DevTools to determine static HTML vs. JS-rendered content. Identify direct XHR/JSON endpoints before writing any scraper code. This is the Phase 1 day-one task.
- **Vapor version:** Confirm whether Vapor 5.0 has shipped. If yes, use Vapor 5 (Swift 6 strict concurrency support built-in). Check https://github.com/vapor/vapor/releases.
- **vapor/apns package:** Verify current version and compatibility with target Vapor major version.
- **StatBroadcast rate limits:** No published limit exists. Start with a conservative scrape interval (one scoreboard page request per 60s during testing) and observe for 429/403 responses before tightening to 30s.
- **Conference theme divergence:** StatBroadcast uses conference-specific themes (`theme=accgamecenter` etc.). The parser adapter architecture must be tested against ACC, Big Ten, and Ivy League pages — structural differences may exist.
- **Team logo licensing:** Verify usage rights for D1 school logos before App Store submission. Most schools publish brand guidelines with usage terms.

## Sources

### Primary (HIGH confidence)
- `/Users/darrenbrelesky/Documents/claude-code/BarDown/UI-guidelines.md` — Compiled Feb 2026 from Apple WWDC25 sessions (219, 356, 323); Liquid Glass design constraints, GlassKit patterns, SwiftUI iOS 26 APIs
- `/Users/darrenbrelesky/Documents/claude-code/BarDown/.planning/PROJECT.md` — Project requirements, data sources, StatBroadcast URLs, design constraints
- Apple Developer Documentation (APNs HTTP/2 API, UserNotifications, SwiftData, BackgroundTasks, WidgetKit, ActivityKit) — referenced in UI-guidelines.md

### Secondary (MEDIUM confidence)
- Apple WWDC25-219: Meet Liquid Glass — Liquid Glass usage rules and constraints
- Apple WWDC25-356: Get to Know the New Design System — navigation vs. content hierarchy
- Apple WWDC25-323: Build a SwiftUI App with the New Design — implementation patterns
- Training data (cutoff May 2025) — Vapor, SwiftSoup, PostgreSQL, Redis architecture patterns; ESPN/theScore/CBS Sports feature analysis; sports app UX patterns (FotMob, Sofascore, MLB At Bat, NHL app)

### Tertiary (LOW confidence — needs validation)
- StatBroadcast HTML structure — referenced via PROJECT.md URLs; actual DOM structure unverified; JS-rendering status unknown
- Vapor 4.x vs 5.x version status — training data cutoff predates possible Vapor 5 release
- Railway vs Fly.io current pricing — needs current pricing verification

---
*Research completed: 2026-02-24*
*Ready for roadmap: yes*
