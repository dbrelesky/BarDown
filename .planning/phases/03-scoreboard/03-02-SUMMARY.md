---
phase: 03-scoreboard
plan: 02
subsystem: testing
tags: [swift-testing, tdd, fixtures, ios, xcode, json-decoding]

# Dependency graph
requires:
  - phase: 03-scoreboard
    provides: Plan 03-01 game dates endpoint (provides knowledge of GameResponse DTO shape)
  - phase: 02-design-system-app-shell
    provides: BarDownTests target structure and GlassAuditTests.swift pattern
provides:
  - RED phase test scaffolds for GameModel, ScoreboardViewModel, DateStripViewModel
  - games-response.json fixture with live, scheduled, and final game objects
  - Contract for implementation plans 03-03 through 03-06 to satisfy
affects: [03-03, 03-04, 03-05, 03-06]

# Tech tracking
tech-stack:
  added: []
  patterns: [TDD RED phase with compile-error-as-failing-test, Bundle(for:) NSObject helper for fixture loading in Swift Testing value types]

key-files:
  created:
    - BarDown-iOS/BarDownTests/Fixtures/games-response.json
    - BarDown-iOS/BarDownTests/GameModelTests.swift
    - BarDown-iOS/BarDownTests/ScoreboardViewModelTests.swift
    - BarDown-iOS/BarDownTests/DateStripTests.swift
  modified: []

key-decisions:
  - "Bundle(for: NSObjectSubclass.self) required because Swift Testing test structs are value types; added *Helper NSObject subclass in each test file for fixture loading"
  - "Tests reference GameModel, ScoreboardViewModel, and DateStripViewModel which do not yet exist; compile errors ARE the failing RED tests"
  - "ScoreboardViewModel state machine designed with .loading/.empty/.loaded/.error cases and explicit loadGames/loadError methods"
  - "DateStripViewModel takes gameDates array and selectionSink ViewModel; displays only supplied dates (not full calendar range)"

patterns-established:
  - "TDD RED pattern: write tests referencing types before types exist; compile failure = test failure"
  - "NSObject helper class pattern for Bundle(for:) fixture loading in Swift Testing (value type test structs cannot use Bundle(for:) directly)"
  - "Fixture files in BarDown-iOS/BarDownTests/Fixtures/ picked up automatically by project.yml recursive BarDownTests source path"

requirements-completed: [SCOR-01, SCOR-02, SCOR-03, SCOR-06, SCOR-07]

# Metrics
duration: 1min
completed: 2026-02-25
---

# Phase 03 Plan 02: Wave 0 Test Scaffolds Summary

**RED phase TDD scaffolds for GameModel JSON decoding, ScoreboardViewModel state machine, and DateStripViewModel date filtering using Swift Testing framework**

## Performance

- **Duration:** ~1 min
- **Started:** 2026-02-25T18:18:38Z
- **Completed:** 2026-02-25T18:19:40Z
- **Tasks:** 1 (TDD RED phase - single task covering all 4 files)
- **Files modified:** 4 created, 0 modified

## Accomplishments

- Created games-response.json fixture with one live, one scheduled, and one final lacrosse game matching the GameResponse DTO shape (id, homeTeam, awayTeam, homeScore, awayScore, status, period, clock, startTime ISO8601, quarterScores array)
- Created GameModelTests.swift testing JSON decoding, status fields, TeamModel fields, and gameStatus sort order
- Created ScoreboardViewModelTests.swift testing state machine transitions (.loading -> .empty/.loaded/.error), isRefreshing toggle, and selectedDate Eastern timezone default
- Created DateStripTests.swift testing sparse date display (only game dates, not every calendar day), date selection propagation to ScoreboardViewModel, and formatter timezone correctness
- App target (BarDown) builds clean - verified with xcodebuild

## Task Commits

Each task was committed atomically:

1. **Task 1: Wave 0 test scaffolds (RED phase)** - `255197e` (test)

**Plan metadata:** (to be committed with SUMMARY.md)

_Note: TDD RED phase - single commit covering all 4 files. Compile errors on test target are intentional and expected._

## Files Created/Modified

- `BarDown-iOS/BarDownTests/Fixtures/games-response.json` - JSON fixture with 3 game objects (live, scheduled, final) matching GameResponse DTO shape
- `BarDown-iOS/BarDownTests/GameModelTests.swift` - Unit tests for GameModel/TeamModel JSON decoding and gameStatus sort order
- `BarDown-iOS/BarDownTests/ScoreboardViewModelTests.swift` - Unit tests for ViewModel state machine transitions, isRefreshing, and selectedDate default
- `BarDown-iOS/BarDownTests/DateStripTests.swift` - Unit tests for sparse date display, selection, and Eastern timezone formatter

## Decisions Made

- **Bundle(for: NSObjectSubclass) pattern:** Swift Testing test structs are value types and cannot be used with `Bundle(for:)` which requires AnyClass. Added a minimal `final class *TestsHelper: NSObject {}` in each test file that needs fixture loading. This is a standard pattern for Swift Testing fixture loading.
- **ScoreboardViewModel API surface:** Tests define an explicit API: `loadGames(_ games: [GameModel]) async`, `loadError(_ message: String) async`, `refresh() async`, `selectedDate: Date`, `isRefreshing: Bool`, `state: ScoreboardState`. Plan 03-04 must implement this exact API.
- **DateStripViewModel API surface:** Tests define: `init(gameDates: [Date])`, `init(gameDates: [Date], selectionSink: ScoreboardViewModel)`, `displayDates: [Date]`, `select(_ date: Date)`, `label(for date: Date) -> String`. Plan 03-04 or 03-05 must implement this.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Test scaffolds define the contract for 03-03 (GameModel/TeamModel types), 03-04 (ScoreboardViewModel), and 03-05 (DateStripViewModel)
- App target builds clean; test target compile failures are expected RED state
- Fixture JSON validates and covers all three game statuses needed for tests
- No blockers; 03-03 can proceed immediately

---
*Phase: 03-scoreboard*
*Completed: 2026-02-25*
