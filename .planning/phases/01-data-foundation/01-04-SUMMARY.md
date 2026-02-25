---
phase: 01-data-foundation
plan: 04
subsystem: scraper
tags: [swift, vapor, statbroadcast, box-score, scheduler]

# Dependency graph
requires:
  - phase: 01-data-foundation/01-02
    provides: "StatBroadcastScraper.scrapeBoxScore(), BoxScoreParser, DataReconciler.reconcileBoxScore()"
provides:
  - "Active box score scraping pipeline in ScraperScheduler for live/final games"
  - "scrapeBoxScores(for:) method wired into scrapeConference() flow"
affects: [02-live-experience, box-score-audit]

# Tech tracking
tech-stack:
  added: []
  patterns: ["Per-game try/catch isolation for scraping resilience", "Skip-if-already-scraped guard to avoid redundant work"]

key-files:
  created: []
  modified:
    - Sources/App/Scraper/ScraperScheduler.swift

key-decisions:
  - "Used conference filter on homeTeam relationship to scope box score queries per conference"
  - "Skip games with existing playerStats to prevent redundant scraping of completed games"

patterns-established:
  - "Box score scraping gated behind statBroadcastID presence and game status (live/final)"
  - "Individual game try/catch so one box score failure does not block the rest"

requirements-completed: [DATA-01, DATA-04]

# Metrics
duration: 3min
completed: 2026-02-25
---

# Phase 01 Plan 04: Box Score Wiring Summary

**Wired box score scraping pipeline into ScraperScheduler so live/final games with StatBroadcast IDs automatically fetch player stats and quarter scores**

## Performance

- **Duration:** 3 min
- **Started:** 2026-02-25T12:41:10Z
- **Completed:** 2026-02-25T12:44:35Z
- **Tasks:** 1
- **Files modified:** 1

## Accomplishments
- Added `scrapeBoxScores(for:)` method that queries live/final games with StatBroadcast external IDs
- Wired the call into `scrapeConference()` after NCAA and StatBroadcast scoreboard scraping
- Each game's box score scrape is isolated with try/catch for resilience
- Games with existing player stats are skipped to avoid redundant work
- Results flow through `reconciler.reconcileBoxScore()` for database persistence

## Task Commits

Each task was committed atomically:

1. **Task 1: Wire box score scraping into ScraperScheduler** - `752714e` (feat)

**Plan metadata:** pending (docs: complete plan)

## Files Created/Modified
- `Sources/App/Scraper/ScraperScheduler.swift` - Added scrapeBoxScores(for:) method and call site in scrapeConference()

## Decisions Made
- Filtered games by homeTeam conference relationship rather than a separate conference-to-game join, keeping the query simple within Fluent's eager loading
- Used `.with(\.$playerStats)` eager load to check for existing stats rather than a separate count query, avoiding an extra DB round-trip

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
- Stale Swift build cache showed a pre-existing error in RateLimitMiddleware.swift that was already fixed on disk; resolved with `swift package clean` before rebuild

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Box score pipeline is wired and compiles; will activate automatically when StatBroadcast selectors are verified during a live game browser audit
- The scrapeBoxScore() endpoint URLs are speculative -- a live game audit (Phase 2 or separate task) is needed to discover correct XHR endpoints
- All Phase 1 gap closure plans (04, 05) can proceed independently

---
*Phase: 01-data-foundation*
*Completed: 2026-02-25*
