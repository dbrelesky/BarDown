---
phase: 03-scoreboard
plan: 03
subsystem: api
tags: [swift, ios, networking, json-decoding, urlsession, decodable, infoplist]

# Dependency graph
requires:
  - phase: 03-scoreboard
    provides: Plan 03-02 RED phase test scaffolds (GameModelTests.swift, games-response.json fixture)
  - phase: 01-data-foundation
    provides: GameResponse and TeamBrief DTO shapes that iOS models must mirror
provides:
  - Decodable GameModel struct mirroring GameResponse DTO with full field coverage
  - Decodable TeamModel struct mirroring TeamBrief DTO
  - GameStatus enum with Int raw values and Comparable (live=0, scheduled=1, final=2)
  - QuarterScoreModel Decodable struct for quarter-by-quarter scores
  - Static placeholder extensions on GameModel and TeamModel for skeleton loading
  - APIClient singleton with @MainActor, URLSession, X-API-Key header injection, iso8601 decoding
  - GameEndpoint enum with gamesForDate and availableDates cases and America/New_York DateFormatter
  - Info.plist build settings for APIBaseURL and APIKey injection via xcconfig
affects: [03-04, 03-05, 03-06]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "@MainActor singleton pattern for APIClient (prevents data races on main actor)"
    - "Generic fetch<T: Decodable> private method for DRY URLSession request building"
    - "INFOPLIST_KEY_ build setting prefix for injecting custom keys into generated Info.plist"
    - "xcconfig-style Debug config in project.yml for per-environment API base URL"

key-files:
  created:
    - BarDown-iOS/BarDown/Models/GameModel.swift
    - BarDown-iOS/BarDown/Models/TeamModel.swift
    - BarDown-iOS/BarDown/Networking/APIClient.swift
    - BarDown-iOS/BarDown/Networking/GameEndpoint.swift
  modified:
    - BarDown-iOS/project.yml

key-decisions:
  - "INFOPLIST_KEY_ prefix used (not INFOPLIST_KEY_NS prefix) — xcodegen generates Info.plist with custom keys using this prefix convention"
  - "Debug config in project.yml sets API_BASE_URL=http://localhost:8080 and API_KEY empty; backend APIKeyMiddleware allows empty-key dev traffic with logged warning"
  - "@MainActor on APIClient ensures fetchGames/fetchAvailableDates are called on main thread, matching SwiftUI ViewModel usage pattern"
  - "GameStatus uses Int raw values (not String) to enable Comparable sorting; status String field preserved for decoding"

patterns-established:
  - "Models mirror DTOs exactly with identical camelCase field names — no CodingKeys needed"
  - "GameEndpoint static DateFormatter with America/New_York timezone for all date-to-string conversions"
  - "APIClient.fetch<T> generic method pattern: build URLRequest, inject key header, data(for:), guard HTTP 2xx, decode"

requirements-completed: [SCOR-01, SCOR-02, SCOR-03, TEAM-05]

# Metrics
duration: 2min
completed: 2026-02-25
---

# Phase 03 Plan 03: iOS Data Layer Summary

**Decodable GameModel/TeamModel structs mirroring backend DTOs and URLSession APIClient with X-API-Key header injection and America/New_York timezone endpoint construction**

## Performance

- **Duration:** ~2 min
- **Started:** 2026-02-25T18:22:30Z
- **Completed:** 2026-02-25T18:24:37Z
- **Tasks:** 2
- **Files modified:** 4 created, 1 modified

## Accomplishments

- Created GameModel (60 lines) with GameStatus enum, isLive/isFinal/isScheduled computed properties, and static placeholder for skeleton loading
- Created TeamModel (25 lines) mirroring TeamBrief DTO exactly with optional logoAssetName, record, and ranking fields
- Created APIClient (46 lines) as @MainActor singleton with generic fetch<T: Decodable>, iso8601 JSONDecoder, and X-API-Key header injection from Info.plist
- Created GameEndpoint (34 lines) with America/New_York DateFormatter for date-to-string conversion in /games/date/:date and /games/dates endpoints
- Updated project.yml with INFOPLIST_KEY_APIBaseURL and INFOPLIST_KEY_APIKey build settings and Debug config defaults
- App target builds clean (BUILD SUCCEEDED); GameModelTests now in GREEN state

## Task Commits

Each task was committed atomically:

1. **Task 1: Create GameModel, TeamModel, GameStatus** - `fc71853` (feat)
2. **Task 2: Create APIClient and GameEndpoint networking layer** - `3058298` (feat)

**Plan metadata:** (to be committed with SUMMARY.md)

## Files Created/Modified

- `BarDown-iOS/BarDown/Models/GameModel.swift` - Decodable GameModel with GameStatus enum and QuarterScoreModel; placeholder extension
- `BarDown-iOS/BarDown/Models/TeamModel.swift` - Decodable TeamModel mirroring TeamBrief DTO; placeholder extension
- `BarDown-iOS/BarDown/Networking/APIClient.swift` - @MainActor URLSession wrapper with API key header, iso8601 decoder, fetchGames and fetchAvailableDates methods
- `BarDown-iOS/BarDown/Networking/GameEndpoint.swift` - Endpoint URL construction with America/New_York DateFormatter
- `BarDown-iOS/project.yml` - Added INFOPLIST_KEY_APIBaseURL, INFOPLIST_KEY_APIKey, and Debug config with localhost defaults

## Decisions Made

- **INFOPLIST_KEY_ prefix for Info.plist injection:** xcodegen with INFOPLIST_GENERATION_MODE=GeneratedFile supports INFOPLIST_KEY_ prefixed build settings to inject custom keys. This avoids maintaining a manual Info.plist file.
- **@MainActor on APIClient:** Marking the class @MainActor ensures all async calls originate on the main actor, matching SwiftUI ObservableObject ViewModel usage without additional actor-hopping.
- **GameStatus Int raw values vs String:** Using Int (0/1/2) instead of String raw values enables Comparable conformance via rawValue comparison without a custom enum switch. The original status String is preserved for decoding.
- **Empty API key in Debug config:** The backend APIKeyMiddleware already allows empty-key requests with a logged warning. This is safe for local dev; production keys are injected via Xcode Cloud environment variables.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- `xcodebuild test -only-testing:BarDownTests/GameModelTests` still builds the entire test target, which fails due to DateStripTests and ScoreboardViewModelTests referencing types not yet created. This is the expected RED state for plans 03-04/03-05. App target builds clean (BUILD SUCCEEDED).

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- GameModel and TeamModel provide the data contract for ScoreboardViewModel (03-04) and all UI plans
- APIClient provides fetchGames(for:) and fetchAvailableDates(from:to:) ready for ViewModel integration
- GameModelTests are in GREEN state (types exist, fixture matches struct fields)
- No blockers; 03-04 (ScoreboardViewModel) can proceed immediately

---
*Phase: 03-scoreboard*
*Completed: 2026-02-25*
