---
phase: 03-scoreboard
plan: "04"
subsystem: ui
tags: [swiftui, observation, @observable, viewmodel, date-strip, calendar, ios26]

# Dependency graph
requires:
  - phase: 03-scoreboard/03-03
    provides: APIClient with fetchGames(for:) and fetchAvailableDates(from:to:), GameModel, GameStatus

provides:
  - ScoreboardViewModel: @Observable @MainActor state machine (loading/loaded/empty/error), selectedDate, gameDates, isRefreshing
  - DateStripViewModel: nonisolated view model for date strip — displayDates, select(), label()
  - DateStripView: horizontal scrollable date selector using ScrollViewReader + LazyHStack
  - CalendarSheetView: half-sheet monthly calendar with dot indicators on game dates

affects: [03-05-scoreboard-ui, future game detail phase]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "@Observable @MainActor final class for SwiftUI ViewModels (no ObservableObject)"
    - "Testable overloads: loadGames([GameModel]) and loadError(String) alongside network-facing loadGames(for: Date)"
    - "DateStripViewModel is nonisolated class — only select() is @MainActor to allow nonisolated test access"
    - "xcodegen regeneration required when adding new Swift files to include them in xcodeproj"

key-files:
  created:
    - BarDown-iOS/BarDown/Features/Scoreboard/ScoreboardViewModel.swift
    - BarDown-iOS/BarDown/Features/Scoreboard/DateStripViewModel.swift
    - BarDown-iOS/BarDown/Features/Scoreboard/DateStripView.swift
    - BarDown-iOS/BarDown/Features/Scoreboard/CalendarSheetView.swift
  modified:
    - BarDown-iOS/BarDown.xcodeproj/project.pbxproj

key-decisions:
  - "ScoreboardViewModel.selectedDate initialized in init() not as property default — covariant Self type cannot be used in stored property initializer"
  - "DateStripViewModel is nonisolated (not @MainActor) — tests call init/displayDates/label() from nonisolated context; only select() is @MainActor"
  - "sortedByStatus() extension on [GameModel] uses GameStatus Comparable (Int rawValues: live=0, scheduled=1, final=2)"

patterns-established:
  - "Scoreboard feature files live in BarDown-iOS/BarDown/Features/Scoreboard/"
  - "Testable ViewModel pattern: separate data-loading overloads that accept pre-fetched data for unit testing"

requirements-completed: [SCOR-04, SCOR-05, SCOR-06, SCOR-07]

# Metrics
duration: 5min
completed: 2026-02-25
---

# Phase 3 Plan 4: Scoreboard ViewModel Summary

**@Observable ScoreboardViewModel state machine with testable overloads, DateStripViewModel/View for game-date-only navigation, and CalendarSheetView half-sheet with dot indicators**

## Performance

- **Duration:** 5 min
- **Started:** 2026-02-25T18:28:13Z
- **Completed:** 2026-02-25T18:33:30Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- ScoreboardViewModel: @Observable @MainActor with State enum (loading/loaded/empty/error), selectedDate defaulting to Eastern start-of-day, gameDates for strip, isRefreshing for pull-to-refresh
- DateStripViewModel: nonisolated class with displayDates, select(), label() — designed so tests can call from nonisolated context while select() remains @MainActor
- DateStripView: horizontal ScrollViewReader + LazyHStack rendering only game dates; selected date gets subtle tint capsule highlight; auto-scrolls to today on appear
- CalendarSheetView: .presentationDetents([.medium]) half-sheet, LazyVGrid with leading weekday offset, dot indicators on game dates, month navigation
- All 9 tests GREEN: ScoreboardViewModelTests (5 tests) + DateStripTests (4 tests); GlassAuditTests still pass

## Task Commits

Each task was committed atomically:

1. **Task 1: ScoreboardViewModel and DateStripViewModel** - `ce5b197` (feat)
2. **Task 2: DateStripView, CalendarSheetView, Swift 6 concurrency fixes** - `9a536e9` (feat)

**Plan metadata:** (docs commit follows)

## Files Created/Modified

- `BarDown-iOS/BarDown/Features/Scoreboard/ScoreboardViewModel.swift` - @Observable @MainActor state machine; loadGames(for:)/loadGames([GameModel])/loadError() overloads; refresh(); sortedByStatus() extension
- `BarDown-iOS/BarDown/Features/Scoreboard/DateStripViewModel.swift` - Nonisolated class; displayDates, select() @MainActor, label() with Eastern DateFormatter
- `BarDown-iOS/BarDown/Features/Scoreboard/DateStripView.swift` - Horizontal ScrollViewReader + LazyHStack; @Bindable viewModel; DateCell with capsule selection highlight
- `BarDown-iOS/BarDown/Features/Scoreboard/CalendarSheetView.swift` - Half-sheet monthly calendar; DayCell with dot indicator; presentationDetents([.medium])
- `BarDown-iOS/BarDown.xcodeproj/project.pbxproj` - Regenerated via xcodegen to include new Scoreboard feature files

## Decisions Made

- `ScoreboardViewModel.selectedDate` moved to `init()` because Swift does not allow `Self.staticMethod()` as a stored property default value in a class
- `DateStripViewModel` made nonisolated so tests like `onlyGameDatesDisplayed` and `formatterUsesEasternTimezone` (which lack `@MainActor`) can construct and use it — only `select()` needs `@MainActor` since it mutates the `@MainActor` ScoreboardViewModel
- Implemented both plan-described API (`loadGames(for: Date)`) and test-required API (`loadGames([GameModel])`) — the network method calls the data method internally

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed covariant Self in stored property initializer**
- **Found during:** Task 1 (ScoreboardViewModel compilation)
- **Issue:** `var selectedDate: Date = Self.easternStartOfToday()` is invalid Swift — covariant Self cannot be used in stored property defaults in a class
- **Fix:** Moved initialization to `init()` using `ScoreboardViewModel.easternStartOfToday()`
- **Files modified:** BarDown-iOS/BarDown/Features/Scoreboard/ScoreboardViewModel.swift
- **Verification:** Build succeeded
- **Committed in:** 9a536e9 (Task 2 commit)

**2. [Rule 1 - Bug] Fixed DateStripViewModel @MainActor isolation mismatch with tests**
- **Found during:** Task 2 (running DateStripTests)
- **Issue:** DateStripViewModel was `@MainActor` but tests call `init()`, `displayDates`, and `label(for:)` from nonisolated test functions — Swift 6 strict concurrency rejects this
- **Fix:** Removed `@MainActor` from class; kept only `select()` as `@MainActor`; changed `selectionSink` from `weak var` to `let` (constant reference to @MainActor object, accessed only from @MainActor context via select())
- **Files modified:** BarDown-iOS/BarDown/Features/Scoreboard/DateStripViewModel.swift
- **Verification:** All 9 tests pass GREEN
- **Committed in:** 9a536e9 (Task 2 commit)

**3. [Rule 3 - Blocking] Regenerated xcodeproj to include new Scoreboard files**
- **Found during:** Task 2 (running tests after creating files)
- **Issue:** New Swift files added to BarDown-iOS/BarDown/Features/Scoreboard/ were not visible to the test target — "Cannot find 'DateStripViewModel' in scope"
- **Fix:** Ran `xcodegen generate` in BarDown-iOS/ to regenerate project.pbxproj from project.yml
- **Files modified:** BarDown-iOS/BarDown.xcodeproj/project.pbxproj
- **Verification:** Tests compiled and passed after regeneration
- **Committed in:** 9a536e9 (Task 2 commit)

---

**Total deviations:** 3 auto-fixed (2 bugs, 1 blocking)
**Impact on plan:** All auto-fixes necessary for correctness and test compatibility. No scope creep.

## Issues Encountered

- Tests defined a different API than the plan described: `ScoreboardViewModel.loadGames([GameModel])` (not `loadGames(for: Date)`) and `loadError(String)` for unit testing without network calls. Both the plan's network-facing API and the test's data-facing API were implemented — the network method calls the data method internally.
- `DateStripTests` do not test `DateStripView` directly — they test a `DateStripViewModel` class that the plan described as part of `DateStripView.swift`. The VM was extracted to its own file for clean separation.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- ScoreboardViewModel state machine is complete and tested — ready to wire into ScoreboardView (03-05)
- DateStripView and CalendarSheetView are ready to embed in ScoreboardView
- All 9 ViewModel/date-navigation tests pass; GlassAuditTests unaffected
- No blockers for 03-05

---
*Phase: 03-scoreboard*
*Completed: 2026-02-25*

## Self-Check: PASSED

All created files verified on disk. Task commits ce5b197 and 9a536e9 confirmed in git log.
