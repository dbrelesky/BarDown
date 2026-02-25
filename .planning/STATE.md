# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-02-24)

**Core value:** When a fan opens BarDown on game day, they instantly see every live D1 lacrosse score and can drill into any game for full, real-time detail -- faster and more beautifully than any alternative.
**Current focus:** Phase 2: Design System & App Shell

## Current Position

Phase: 2 of 7 (Design System & App Shell)
Plan: 0 of 1 in current phase
Status: Phase 2 not started (Phase 1 verified and complete)
Last activity: 2026-02-25 -- Phase 1 approved and marked complete

Progress: [###.......] 30%

## Performance Metrics

**Velocity:**
- Total plans completed: 5
- Average duration: 5 min
- Total execution time: 0.5 hours

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 01-data-foundation | 5 | 27 min | 5 min |

**Recent Trend:**
- Last 5 plans: 01-01 (6m), 01-02 (7m), 01-03 (8m), 01-04 (3m), 01-05 (3m)
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
Stopped at: Phase 1 verified and approved — ready for Phase 2
Resume file: .planning/ROADMAP.md
