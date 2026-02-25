---
phase: 03-scoreboard
plan: 01
subsystem: api
tags: [vapor, swift, fluent, timezone, rest-api]

# Dependency graph
requires:
  - phase: 01-data-foundation
    provides: Game Fluent model with startTime field and database query infrastructure
provides:
  - GET /api/v1/games/dates endpoint returning sorted yyyy-MM-dd date strings for days with games
  - Optional from/to query param filtering with ±30-day default window
affects: [ios-date-strip, scoreboard-ui, 03-02, 03-03]

# Tech tracking
tech-stack:
  added: []
  patterns: [Fluent .field() projection to minimize data transfer, Set-based Swift deduplication instead of Fluent .unique()]

key-files:
  created: []
  modified:
    - Sources/App/Controllers/GameController.swift

key-decisions:
  - "Set-based deduplication in Swift instead of Fluent .unique() — .unique() has limited cross-driver support"
  - "Default ±30-day window when from/to params omitted — matches iOS date strip scroll range"
  - "Use .field(\\.$startTime) projection to avoid loading full Game model for a dates-only query"

patterns-established:
  - "Lightweight projection pattern: use .field() to select only required columns when full model load unnecessary"

requirements-completed: [SCOR-04]

# Metrics
duration: 2min
completed: 2026-02-25
---

# Phase 03 Plan 01: Game Dates Endpoint Summary

**Lightweight `GET /api/v1/games/dates` Vapor endpoint returning sorted yyyy-MM-dd strings for days with games, using America/New_York timezone and Set deduplication**

## Performance

- **Duration:** 2 min
- **Started:** 2026-02-25T18:15:17Z
- **Completed:** 2026-02-25T18:16:31Z
- **Tasks:** 1
- **Files modified:** 1

## Accomplishments

- Registered `GET /api/v1/games/dates` route in `GameController.boot()`
- Implemented `gameDates` handler returning sorted `[String]` of `yyyy-MM-dd` date strings
- Handler accepts optional `from` and `to` query params; defaults to ±30-day window
- Uses `America/New_York` timezone boundaries consistent with `gamesByDate` and `dateBounds(for:)`
- Uses `.field(\.$startTime)` projection query to minimize data transfer (no eagerly-loaded relations)
- Deduplicates via `Set<String>` before sorting (avoids Fluent `.unique()` cross-driver compatibility issues)

## Task Commits

Each task was committed atomically:

1. **Task 1: Add GET /api/v1/games/dates endpoint to GameController** - `97e1e87` (feat)

**Plan metadata:** (docs commit below)

## Files Created/Modified

- `Sources/App/Controllers/GameController.swift` - Added `gameDates` route registration and handler (34 lines added)

## Decisions Made

- Used `Set`-based deduplication in Swift instead of Fluent `.unique()` operator — `.unique()` has limited support across database drivers
- Default ±30-day window matches the iOS date strip scroll range, avoiding over-fetch or under-fetch
- Used `.field(\.$startTime)` projection to select only the startTime column, avoiding unnecessary full model loads

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- `GET /api/v1/games/dates` endpoint is live and compiled clean
- iOS date strip can now discover which dates have games with a single request
- Ready for Phase 03 Plan 02 (iOS ScoreboardView integration)

---
*Phase: 03-scoreboard*
*Completed: 2026-02-25*

## Self-Check: PASSED

- FOUND: Sources/App/Controllers/GameController.swift
- FOUND: .planning/phases/03-scoreboard/03-01-SUMMARY.md
- FOUND: commit 97e1e87 (feat(03-01): add GET /api/v1/games/dates endpoint)
- FOUND: gameDates function in GameController
- FOUND: route registration (games.get("dates"))
