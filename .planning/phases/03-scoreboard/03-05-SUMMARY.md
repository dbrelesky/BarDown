---
phase: 03-scoreboard
plan: 05
subsystem: ui
tags: [swiftui, kingfisher, ios, scoreboard, game-card]

# Dependency graph
requires:
  - phase: 03-03
    provides: GameModel and TeamModel structs used as input to all card components

provides:
  - GameCardView: composed full-width game card rendering any game state (live/final/scheduled)
  - TeamRowView: single team row with KFImage URL logo, abbreviation, record, ranking pill
  - ScoreCenterView: center status block (LIVE+indicator, FINAL, or start time)
  - LiveIndicator: blinking red circle animation using SwiftUI repeatForever
  - Kingfisher 8.0.3 SPM dependency for URL-based logo caching

affects: [03-04, 04-scoreboard-integration, 05-game-detail]

# Tech tracking
tech-stack:
  added: [Kingfisher 8.0.3 (onevcat/Kingfisher, merged KingfisherSwiftUI in v8)]
  patterns: [composed view hierarchy (atoms -> molecule -> organism), KFImage URL/asset fallback pattern, DESG-02 opaque card backgrounds]

key-files:
  created:
    - BarDown-iOS/BarDown/Features/Scoreboard/LiveIndicator.swift
    - BarDown-iOS/BarDown/Features/Scoreboard/TeamRowView.swift
    - BarDown-iOS/BarDown/Features/Scoreboard/ScoreCenterView.swift
    - BarDown-iOS/BarDown/Features/Scoreboard/GameCardView.swift
  modified:
    - BarDown-iOS/project.yml

key-decisions:
  - "Kingfisher 8.x uses single 'Kingfisher' product (not 'KingfisherSwiftUI') and single 'import Kingfisher' statement — products were merged in v6+"
  - "DESG-02 guard comment reworded to not contain literal '.glassEffect' string (GlassAuditTests regex scan flags even comments)"
  - "Card background: Color(.secondarySystemGroupedBackground) — fully opaque, adapts dark/light mode, DESG-02 compliant"
  - "Live accent: subtle red shadow + Color.red.opacity(0.3) border stroke (not heavy glow)"
  - "Divider inset 80pt aligns with team name start (after 52pt logo + 16pt gap + 12pt spacing)"
  - "No onTapGesture on GameCardView — Phase 3 is view-only; tap navigation in Phase 5"

patterns-established:
  - "TeamLogoView: URL check via URL(string:) — if valid URL use KFImage, else local Image asset, else systemImage fallback"
  - "Winner detection: isFinal && awayScore > homeScore (computed var, no state)"
  - "DESG-02 guard: comment as 'no glass modifiers' without the literal .glassEffect string"

requirements-completed: [SCOR-02, SCOR-03, TEAM-05]

# Metrics
duration: 5min
completed: 2026-02-25
---

# Phase 3 Plan 05: Game Card Components Summary

**Kingfisher-powered game card hierarchy (GameCardView, TeamRowView, ScoreCenterView, LiveIndicator) rendering all three game states with DESG-02 opaque backgrounds**

## Performance

- **Duration:** 5 min
- **Started:** 2026-02-25T18:40:08Z
- **Completed:** 2026-02-25T18:42:06Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments
- Kingfisher 8.0.3 added as SPM dependency for URL-based team logo caching
- Full game card component hierarchy built: LiveIndicator -> TeamLogoView -> TeamRowView -> ScoreCenterView -> GameCardView
- All three game states handled: LIVE (blinking indicator + period/clock), FINAL (bold winner, "FINAL" label), SCHEDULED (start time in ET)
- GlassAuditTests pass — no `.glassEffect()` leaks in any card file, DESG-02 compliant

## Task Commits

Each task was committed atomically:

1. **Task 1: Add Kingfisher SPM dependency and create TeamRowView + LiveIndicator** - `3baefab` (feat)
2. **Task 2: Create ScoreCenterView and GameCardView** - `49ae207` (feat)

**Plan metadata:** (docs commit below)

## Files Created/Modified
- `BarDown-iOS/BarDown/Features/Scoreboard/LiveIndicator.swift` - Blinking red circle using SwiftUI repeatForever animation
- `BarDown-iOS/BarDown/Features/Scoreboard/TeamRowView.swift` - Team row: KFImage URL logo with local/systemImage fallback, abbreviation, record, ranking pill, winner bold treatment
- `BarDown-iOS/BarDown/Features/Scoreboard/ScoreCenterView.swift` - Center block: LIVE+indicator+period for live, FINAL for final, ET start time for scheduled
- `BarDown-iOS/BarDown/Features/Scoreboard/GameCardView.swift` - Composed full-width card: away row / center block / home row, opaque background, live red glow
- `BarDown-iOS/project.yml` - Added Kingfisher SPM dependency

## Decisions Made
- Kingfisher 8.x product name is `Kingfisher` (not `KingfisherSwiftUI`) — v8 merged all products into one
- DESG-02 guard comment reworded to avoid containing the literal `.glassEffect` string (audit regex is content-agnostic)
- Card background uses `Color(.secondarySystemGroupedBackground)` — fully opaque, adaptive to dark/light

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed Kingfisher product name from 'KingfisherSwiftUI' to 'Kingfisher'**
- **Found during:** Task 1 (Add Kingfisher SPM dependency)
- **Issue:** project.yml plan specified `product: KingfisherSwiftUI` but Kingfisher 8.x merged all products into a single `Kingfisher` library; also `import KingfisherSwiftUI` became `import Kingfisher`
- **Fix:** Changed product to `- package: Kingfisher` (no `product:` key), updated import in TeamRowView.swift
- **Files modified:** BarDown-iOS/project.yml, BarDown-iOS/BarDown/Features/Scoreboard/TeamRowView.swift
- **Verification:** Build succeeded after fix
- **Committed in:** `3baefab` (Task 1 commit)

**2. [Rule 1 - Bug] Rewrote DESG-02 guard comment to avoid false-positive GlassAuditTest failure**
- **Found during:** Task 2 verification (GlassAuditTests run)
- **Issue:** Plan included comment `// DESG-02: DO NOT add .glassEffect() here` — GlassAuditTests scans all lines for the substring `.glassEffect` (including comments), so the guard comment itself triggered a test failure
- **Fix:** Changed comment to `// DESG-02: game cards must use opaque backgrounds — no glass modifiers`
- **Files modified:** BarDown-iOS/BarDown/Features/Scoreboard/GameCardView.swift
- **Verification:** GlassAuditTests passed after fix
- **Committed in:** `49ae207` (Task 2 commit)

---

**Total deviations:** 2 auto-fixed (2x Rule 1 - Bug)
**Impact on plan:** Both fixes necessary for correctness. No scope creep.

## Issues Encountered
- Kingfisher v8 library consolidation (KingfisherSwiftUI merged into Kingfisher) required product/import name correction — resolved via auto-fix Rule 1

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- GameCardView ready for use in ScoreboardView list (Phase 3 integration, Plan 04's ScoreboardViewModel is already built)
- Kingfisher will cache team logos from URLs provided by the API
- All card states (live/final/scheduled) rendering correctly
- DESG-02 compliance verified by automated audit test

---
*Phase: 03-scoreboard*
*Completed: 2026-02-25*
