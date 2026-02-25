---
phase: 03-scoreboard
plan: 06
subsystem: ui
tags: [swiftui, scoreboard, pull-to-refresh, skeleton, animation, ios26]

# Dependency graph
requires:
  - phase: 03-scoreboard/03-04
    provides: ScoreboardViewModel, DateStripView, CalendarSheetView
  - phase: 03-scoreboard/03-05
    provides: GameCardView, TeamRowView, ScoreCenterView, LiveIndicator

provides:
  - ScoreboardView: main scoreboard list with section grouping, pull-to-refresh, state handling
  - ScoreboardStates: ScoreboardLoadingView (skeleton), ScoreboardEmptyView, ScoreboardErrorView
  - PullToRefreshView: custom bouncing lacrosse ball animation
  - ScoreboardTab: entry point NavigationStack wrapping ScoreboardView (replaces placeholder)
  - ScrollOffsetKey: PreferenceKey for custom pull-to-refresh detection

affects: [04-game-detail, 05-live-updates]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - .task(id:) for reactive data loading on selectedDate change
    - Custom pull-to-refresh via ScrollOffsetKey PreferenceKey (no .refreshable)
    - Skeleton loading via .redacted(reason:) + shimmering opacity pulse
    - Section grouping with collapse/expand for final games

key-files:
  created:
    - BarDown-iOS/BarDown/Features/Scoreboard/ScoreboardView.swift
    - BarDown-iOS/BarDown/Features/Scoreboard/ScoreboardStates.swift
    - BarDown-iOS/BarDown/Features/Scoreboard/PullToRefreshView.swift
  modified:
    - BarDown-iOS/BarDown/Tabs/ScoreboardTab.swift
    - BarDown-iOS/BarDown.xcodeproj/project.pbxproj

key-decisions:
  - "nonisolated(unsafe) on ScrollOffsetKey.defaultValue required for Swift 6 concurrency compliance"
  - "Darwin.sin(Double(phase)) required to resolve ambiguous 'sin' in Swift 6 with CGFloat"
  - "No .refreshable modifier — custom pull detection via ScrollOffsetKey at 60pt threshold"
  - "finalCollapseCount = 3 with showAllFinals toggle — collapse resets on date change"

patterns-established:
  - ".task(id: viewModel.selectedDate) pattern: fires on initial appear AND on every date change"
  - "Section headers use .tracking(1.5) letter-spacing for sport-app aesthetic"
  - "Shimmering modifier: opacity pulse via Darwin.sin on a CGFloat phase variable"

requirements-completed: [SCOR-01, SCOR-06, SCOR-07]

# Metrics
duration: 3min
completed: 2026-02-25
---

# Phase 3 Plan 06: Scoreboard Integration Summary

**ScoreboardView wires ViewModel + DateStrip + GameCards into a fully functional scoreboard with LIVE/UPCOMING/FINAL sections, custom lacrosse ball pull-to-refresh, skeleton loading, and empty/error states — replacing the placeholder ScoreboardTab**

## Performance

- **Duration:** 3 min
- **Started:** 2026-02-25T18:46:18Z
- **Completed:** 2026-02-25T18:49:27Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- ScoreboardView integrates all Phase 3 components: ViewModel, DateStripView, GameCardView, CalendarSheetView
- LIVE/UPCOMING/FINAL section grouping with collapsible Finals (show first 3, "Show X more" button)
- Custom pull-to-refresh using ScrollOffsetKey PreferenceKey — bouncing lacrosse ball animation instead of iOS default spinner
- ScoreboardLoadingView with skeleton cards (.redacted + shimmering opacity pulse animation)
- ScoreboardEmptyView and ScoreboardErrorView with retry button wired to viewModel.refresh()
- ScoreboardTab replaced: NavigationStack wrapping ScoreboardView with large navigation title
- Full test suite passes: 23/23 tests across all suites (GameModelTests, ScoreboardViewModelTests, DateStripTests, GlassAuditTests)

## Task Commits

Each task was committed atomically:

1. **Task 1: Create ScoreboardStates and PullToRefreshView** - `92c8e80` (feat)
2. **Task 2: Create ScoreboardView and update ScoreboardTab** - `fa77011` (feat)

**Plan metadata:** (final commit below)

## Files Created/Modified

- `BarDown-iOS/BarDown/Features/Scoreboard/ScoreboardStates.swift` - Loading skeleton, empty state, error state with retry
- `BarDown-iOS/BarDown/Features/Scoreboard/PullToRefreshView.swift` - Bouncing ball animation + ScrollOffsetKey PreferenceKey
- `BarDown-iOS/BarDown/Features/Scoreboard/ScoreboardView.swift` - Main scoreboard list integrating all components
- `BarDown-iOS/BarDown/Tabs/ScoreboardTab.swift` - Replaced placeholder with NavigationStack + ScoreboardView
- `BarDown-iOS/BarDown.xcodeproj/project.pbxproj` - Updated to include new source files (via xcodegen)

## Decisions Made

- No `.refreshable` modifier — custom pull detection is cleaner for the bouncing ball animation UX
- `nonisolated(unsafe)` on `ScrollOffsetKey.defaultValue` — required for Swift 6 concurrency safety
- `Darwin.sin(Double(phase))` — resolves ambiguous `sin` overloads in Swift 6 with CGFloat types
- `finalCollapseCount = 3` and `showAllFinals` state reset on date change — each day is a fresh view

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed Swift 6 concurrency error on ScrollOffsetKey.defaultValue**
- **Found during:** Task 1 (Create ScoreboardStates and PullToRefreshView)
- **Issue:** `static var defaultValue: CGFloat = 0` caused "nonisolated global shared mutable state" error under Swift 6 strict concurrency
- **Fix:** Changed to `nonisolated(unsafe) static var defaultValue: CGFloat = 0`
- **Files modified:** BarDown-iOS/BarDown/Features/Scoreboard/PullToRefreshView.swift
- **Verification:** Build succeeded after fix
- **Committed in:** `92c8e80` (Task 1 commit)

**2. [Rule 1 - Bug] Fixed ambiguous 'sin' call in ShimmerModifier**
- **Found during:** Task 1 (Create ScoreboardStates and PullToRefreshView)
- **Issue:** `sin(phase)` was ambiguous — Swift 6 couldn't resolve between CGFloat and Double overloads
- **Fix:** Used `Darwin.sin(Double(phase))` with explicit module qualification and type cast; added `import Darwin`
- **Files modified:** BarDown-iOS/BarDown/Features/Scoreboard/ScoreboardStates.swift
- **Verification:** Build succeeded after fix
- **Committed in:** `92c8e80` (Task 1 commit)

---

**Total deviations:** 2 auto-fixed (2 Rule 1 bugs — Swift 6 concurrency/type resolution)
**Impact on plan:** Both fixes were Swift 6 strict concurrency requirements. No scope creep.

## Issues Encountered

- xcodegen regeneration needed twice (after Task 1 and Task 2) to include new Swift source files in xcodeproj — expected behavior per established project pattern (Phase 03 decision: xcodegen regeneration required when adding new Swift files)

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Scoreboard screen is fully functional end-to-end: fetches from API, groups by status, date navigation, pull-to-refresh, all states handled
- Phase 3 complete — all 6 plans executed
- Phase 4 (Game Detail / drill-down) can build on ScoreboardView tap gestures (placeholder noted in GameCardView)
- Phase 5 (Live Updates / WebSocket) can leverage isRefreshing + refresh() patterns already established

---
*Phase: 03-scoreboard*
*Completed: 2026-02-25*
