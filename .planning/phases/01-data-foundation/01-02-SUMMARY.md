---
phase: 01-data-foundation
plan: 02
subsystem: scraper
tags: [vapor, scraping, ncaa-api, statbroadcast, swiftsoup, postgresql, scheduler]

# Dependency graph
requires:
  - phase: 01-data-foundation plan 01
    provides: "Vapor project scaffold with 7 Fluent models and PostgreSQL migrations"
provides:
  - "NCAAAPIScraper fetching scoreboard JSON for all D1 lacrosse games"
  - "StatBroadcastScraper with multi-URL pattern fallback (pending live audit)"
  - "ScoreboardParser and BoxScoreParser for HTML fragment parsing"
  - "ScraperScheduler with smart frequency: 30s live, 5min active, 30min off"
  - "DataReconciler upserting games, teams, players, stats to PostgreSQL"
  - "Actor-based overlap prevention for concurrent scrape protection"
affects: [01-03-PLAN, api-controllers, deployment, live-scores]

# Tech tracking
tech-stack:
  added: [ncaa-casablanca-api, niocore-repeated-task]
  patterns: [actor-based-scheduler, upsert-reconciliation, multi-source-scraping-with-fallback]

key-files:
  created:
    - Sources/App/Scraper/StatBroadcastScraper.swift
    - Sources/App/Scraper/NCAAAPIScraper.swift
    - Sources/App/Scraper/ScraperScheduler.swift
    - Sources/App/Scraper/DataReconciler.swift
    - Sources/App/Scraper/ScraperError.swift
    - Sources/App/Scraper/HTMLParsers/ScoreboardParser.swift
    - Sources/App/Scraper/HTMLParsers/BoxScoreParser.swift
  modified:
    - Sources/App/configure.swift

key-decisions:
  - "NCAA API is primary data source; StatBroadcast is secondary pending live game XHR audit"
  - "NIO RepeatedTask for scheduling instead of VaporCron (simpler for dynamic intervals)"
  - "Actor-based ScraperScheduler for thread-safe overlap prevention"
  - "Teams auto-created on first scrape (not pre-seeded) with conference resolution"

patterns-established:
  - "Multi-source scraping: try primary source, fall back to secondary, reconcile both"
  - "Smart scheduling: frequency adjusts based on live game detection from DB"
  - "Upsert pattern: match by external ID first, then team+date combo, then create new"
  - "Player name parsing: handles 'Last, First' and 'First Last' formats"

requirements-completed: [DATA-01, DATA-03]

# Metrics
duration: 7min
completed: 2026-02-24
---

# Phase 1 Plan 02: Scraping Pipeline Summary

**NCAA API + StatBroadcast scraping pipeline with smart scheduling, PostgreSQL upsert reconciliation, and actor-based overlap prevention**

## Performance

- **Duration:** 7 min
- **Started:** 2026-02-25T04:36:06Z
- **Completed:** 2026-02-25T04:43:00Z
- **Tasks:** 2
- **Files modified:** 8

## Accomplishments

- NCAA Casablanca API verified and integrated as primary scoreboard data source (returns structured JSON with teams, scores, conferences, game state)
- StatBroadcast audit completed: confirmed JS-rendered pages, documented known URL patterns, built multi-pattern scraper ready for live endpoint discovery
- Smart scraper scheduler adjusts frequency per conference: 30s for live games, 5min during active hours, 30min off-hours
- DataReconciler handles full upsert pipeline: games, teams (auto-created), players, quarter scores, team stats, player stats
- Actor-based overlap prevention ensures concurrent scrape jobs never run simultaneously

## Task Commits

Each task was committed atomically:

1. **Task 1: Audit StatBroadcast and build scoreboard + box score scrapers** - `c3d6cab` (feat)
2. **Task 2: Build scraper scheduler and data persistence with reconciliation** - `a7febd6` (feat)

## Files Created/Modified

- `Sources/App/Scraper/StatBroadcastScraper.swift` - StatBroadcast scraper with multi-URL fallback, retry logic, documented audit findings
- `Sources/App/Scraper/NCAAAPIScraper.swift` - NCAA Casablanca JSON API integration with Codable structs matching actual response format
- `Sources/App/Scraper/ScraperScheduler.swift` - Actor-based scheduler with smart frequency adjustment per conference
- `Sources/App/Scraper/DataReconciler.swift` - Upserts scraped data to PostgreSQL (games, teams, players, quarter scores, stats)
- `Sources/App/Scraper/ScraperError.swift` - Typed error enum for scraping pipeline
- `Sources/App/Scraper/HTMLParsers/ScoreboardParser.swift` - StatBroadcast HTML scoreboard parser with multiple selector patterns
- `Sources/App/Scraper/HTMLParsers/BoxScoreParser.swift` - Box score parser for player stats and quarter scores
- `Sources/App/configure.swift` - Updated to start ScraperScheduler on app boot (skipped in test env)

## Decisions Made

- **NCAA API as primary source:** StatBroadcast audit revealed that `scoreboards.php` returns 404 and all data is JS-rendered. The NCAA `data.ncaa.com/casablanca/scoreboard/lacrosse-men/d1/{date}/scoreboard.json` endpoint was verified to work and returns structured game data. StatBroadcast remains as secondary source pending live game XHR endpoint discovery.
- **NCAA boxscore endpoint unavailable for lacrosse:** The `/casablanca/game/{id}/boxscore.json` endpoint returns 404 for lacrosse games. Player-level box score data requires StatBroadcast (future manual audit during live games).
- **NIO RepeatedTask over VaporCron:** VaporCron is better for fixed cron schedules. The scraper needs dynamic intervals (30s vs 5min vs 30min) based on live game state, making NIO's RepeatedTask a better fit.
- **Actor for scheduler:** Swift actor provides built-in thread safety for the `isRunning` flag and `lastScrapeTime` dictionary without manual locking.
- **Teams auto-created:** Instead of pre-seeding all D1 teams, teams are created on first encounter during scraping. This ensures the database only contains teams that actually appear in scraped data.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed Fluent group closure type inference failure in DataReconciler**
- **Found during:** Task 2 (DataReconciler)
- **Issue:** Using `if let` inside a Fluent `.group(.or)` closure caused "reference to member 'first' cannot be resolved without a contextual type"
- **Fix:** Extracted conditional logic outside the group closure, using separate queries for name-only vs name+fullName matching
- **Files modified:** Sources/App/Scraper/DataReconciler.swift
- **Committed in:** a7febd6

**2. [Rule 3 - Blocking] Added NIOCore import for TimeAmount type**
- **Found during:** Task 2 (ScraperScheduler)
- **Issue:** `TimeAmount` type not found in scope -- it's in NIOCore, not re-exported by Vapor
- **Fix:** Added `import NIOCore` to ScraperScheduler.swift
- **Files modified:** Sources/App/Scraper/ScraperScheduler.swift
- **Committed in:** a7febd6

**3. [Rule 1 - Bug] Fixed Logger.Message string concatenation**
- **Found during:** Task 2 (ScraperScheduler)
- **Issue:** Vapor's Logger.Message doesn't support `+` string concatenation in interpolations
- **Fix:** Pre-computed the duration string and used single-line string interpolation
- **Files modified:** Sources/App/Scraper/ScraperScheduler.swift
- **Committed in:** a7febd6

---

**Total deviations:** 3 auto-fixed (2 bugs, 1 blocking)
**Impact on plan:** All fixes necessary for compilation. No scope creep.

## Issues Encountered

- StatBroadcast `scoreboards.php` endpoint returns 404 (not just empty HTML). The events page exists at `/events/` but loads all data client-side via JavaScript. Without a live game browser session, the actual XHR data endpoints cannot be discovered. This was anticipated by the plan (fallback to NCAA API).
- NCAA boxscore endpoint (`/casablanca/game/{id}/boxscore.json`) returns 404 for lacrosse games. This means player-level stats and quarter-by-quarter scoring are not available from the NCAA API. These will require StatBroadcast integration once XHR endpoints are discovered during a live game audit.

## User Setup Required

None - no new external service configuration required. The scraper runs automatically on app boot. To test locally:
1. Start Docker Desktop and PostgreSQL: `docker compose up -d`
2. Run migrations: `swift run App migrate --yes`
3. Start the server: `swift run App serve`
4. Check logs for scraper activity (will attempt NCAA API scrape within 5 seconds of boot)

## Next Phase Readiness

- Scraping pipeline ready to populate database with game data from NCAA API
- Plan 03 (API controllers + deployment) can build endpoints serving this data
- StatBroadcast integration is structurally complete but needs live game XHR endpoint discovery for activation
- Player-level box score data deferred until StatBroadcast endpoints are verified

## Self-Check: PASSED

- All 8 created/modified files verified present on disk
- Commit c3d6cab (Task 1) verified in git log
- Commit a7febd6 (Task 2) verified in git log
- `swift build` completes without errors

---
*Phase: 01-data-foundation*
*Completed: 2026-02-24*
