# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-02-24)

**Core value:** When a fan opens BarDown on game day, they instantly see every live D1 lacrosse score and can drill into any game for full, real-time detail -- faster and more beautifully than any alternative.
**Current focus:** Phase 3 in progress -- Scoreboard

## Current Position

Phase: 3 of 7 (Scoreboard)
Plan: 6 of 7 in current phase (03-06 complete)
Status: Phase 03 in progress
Last activity: 2026-02-25 -- Completed 03-06 (scoreboard integration: ScoreboardView, ScoreboardStates, PullToRefreshView, ScoreboardTab)

Progress: [#######...] 64%

## Performance Metrics

**Velocity:**
- Total plans completed: 9
- Average duration: 5 min
- Total execution time: 0.7 hours

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 01-data-foundation | 5 | 27 min | 5 min |
| 02-design-system-app-shell | 2 | 34 min | 17 min |
| 03-scoreboard | 6 | 18 min | 3 min |

**Recent Trend:**
- Last 5 plans: 03-02 (1m), 03-03 (2m), 03-04 (5m), 03-05 (5m), 03-06 (3m)
- Trend: Steady

*Updated after each plan completion*

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
Recent decisions affecting current work:

- Backend-first build order: scraping pipeline must be validated before any iOS UI work
- StatBroadcast is primary data source; requires hands-on HTML/XHR audit as day-one task
- Shared Swift monorepo (Vapor backend + SwiftUI client) with common data models
- ADR: Swift/Vapor 4 locked as backend stack (moved from Claude's Discretion to Locked Decisions in 01-CONTEXT.md)
- Used SQLPostgresConfiguration with explicit variables (avoids Swift type-checker timeout)
- Raw SQL via SQLKit for index creation (Fluent SchemaBuilder lacks index API)
- Seeded conferences with nil StatBroadcast IDs (Plan 02 audit will discover actual IDs)
- swift-tools-version:5.9 for Dockerfile compatibility
- NCAA API is primary data source; StatBroadcast is secondary pending live game XHR audit
- NIO RepeatedTask for scheduling instead of VaporCron (simpler for dynamic intervals)
- Actor-based ScraperScheduler for thread-safe overlap prevention
- Teams auto-created on first scrape (not pre-seeded) with conference resolution
- Railway deployment deferred by user -- config committed, deploy later with `railway up`
- Controller-DTO pattern established: route handlers map Fluent models to Content-conforming DTOs
- NIOLockedValueBox for thread-safe middleware state instead of actors (simpler for synchronous path)
- Development fallback: allow all API traffic when API_KEY env var is unset, with logged warning
- Rate limiter outer, API key inner in middleware chain -- reject abusive clients before key validation
- [Phase 01]: Box score scraping gated behind statBroadcastID and game status (live/final) with per-game error isolation
- [Phase 02]: swift-tools-version:6.2 required for GlassKit (.iOS(.v26) platform needs PackageDescription 6.2)
- [Phase 02]: xcodegen used for Xcode project generation (reproducible project.yml)
- [Phase 02]: .gitignore updated to track BarDown-iOS xcodeproj (exception from *.xcodeproj/ rule)
- [Phase 02]: Tab API (not deprecated tabItem) for iOS 26 tab navigation
- [Phase 02]: System Liquid Glass on tab bar -- no manual .glassEffect() needed
- [Phase 02]: Opaque .regularMaterial for placeholder content (DESG-02 compliance)
- [Phase 03]: Set-based deduplication in Swift instead of Fluent .unique() — cross-driver compatibility
- [Phase 03]: Default ±30-day window for /api/v1/games/dates matches iOS date strip scroll range
- [Phase 03]: .field() projection on Game.startTime to avoid full model load in dates-only query
- [Phase 03]: Bundle(for: NSObjectSubclass) required for fixture loading in Swift Testing value-type test structs
- [Phase 03]: TDD RED compile-error-as-failing-test pattern — test files reference types before types exist
- [Phase 03]: INFOPLIST_KEY_ prefix injects custom keys into xcodegen-generated Info.plist (no manual Info.plist needed)
- [Phase 03]: @MainActor on APIClient singleton — all fetchGames/fetchAvailableDates calls run on main actor matching SwiftUI ViewModel usage
- [Phase 03]: GameStatus Int raw values (0/1/2) enable Comparable via rawValue; original status String preserved for JSON decoding
- [Phase 03]: Empty API_KEY in Debug xcconfig — backend APIKeyMiddleware allows empty-key dev traffic with logged warning
- [Phase 03]: ScoreboardViewModel.selectedDate initialized in init() — covariant Self cannot be used in stored property default in a class
- [Phase 03]: DateStripViewModel is nonisolated (not @MainActor) — tests call init/displayDates/label() from nonisolated context; only select() is @MainActor
- [Phase 03]: xcodegen regeneration required when adding new Swift files to include them in xcodeproj
- [Phase 03]: Kingfisher 8.x uses single 'Kingfisher' product (not 'KingfisherSwiftUI') and single 'import Kingfisher' statement — products were merged in v6+
- [Phase 03]: GlassAuditTests scan for literal '.glassEffect' string including comments — guard comments must not contain the string
- [Phase 03]: GameCardView uses Color(.secondarySystemGroupedBackground) for DESG-02 opaque card background
- [Phase 03]: nonisolated(unsafe) on ScrollOffsetKey.defaultValue required for Swift 6 strict concurrency compliance
- [Phase 03]: Darwin.sin(Double(phase)) required to resolve ambiguous 'sin' overloads in Swift 6 with CGFloat
- [Phase 03]: No .refreshable modifier in ScoreboardView — custom pull detection via ScrollOffsetKey at 60pt threshold
- [Phase 03]: finalCollapseCount=3 with showAllFinals toggle; resets on date change for fresh per-day view

### Pending Todos

None yet.

### Quality Gates

- Parser fixture tests: scraper output must match expected structured data from saved HTML fixtures
- API contract tests: each endpoint must return JSON matching DTO schemas
- Timezone tests: "today's games" boundary must handle DST spring-forward/fall-back correctly (America/New_York)

### Blockers/Concerns

- StatBroadcast confirmed JS-rendered; scoreboards.php returns 404; XHR endpoints need live game browser audit to discover
- NCAA boxscore endpoint returns 404 for lacrosse -- player stats require StatBroadcast
- Vapor 4 confirmed and locked (Swift 6.2.3 available locally, using swift-tools-version 5.9)
- Team logo licensing must be verified before App Store submission (not blocking TestFlight)

## Session Continuity

Last session: 2026-02-25
Stopped at: Completed 03-06-PLAN.md (scoreboard integration: ScoreboardView, ScoreboardStates, PullToRefreshView, ScoreboardTab)
Resume file: .planning/ROADMAP.md
