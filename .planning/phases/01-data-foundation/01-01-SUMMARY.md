---
phase: 01-data-foundation
plan: 01
subsystem: database
tags: [vapor, fluent, postgresql, swift, docker, railway]

# Dependency graph
requires: []
provides:
  - "Vapor 4 project scaffold with Package.swift and all dependencies"
  - "7 Fluent data models with full lacrosse stat coverage"
  - "PostgreSQL migrations creating all tables with foreign keys and indexes"
  - "5 Phase 1 conferences seeded (Big East, ACC, Big Ten, Patriot League, Ivy League)"
  - "Docker-compose for local PostgreSQL development"
  - "Dockerfile for Railway deployment"
  - "GET /health endpoint for deployment health checks"
affects: [01-02-PLAN, 01-03-PLAN, scrapers, api-controllers, deployment]

# Tech tracking
tech-stack:
  added: [vapor-4.89, fluent-4.8, fluent-postgres-driver-2.7, swiftsoup-2.7, vaporcron-2.6]
  patterns: [fluent-model-with-property-wrappers, async-migration, database-url-parsing, multi-stage-dockerfile]

key-files:
  created:
    - Package.swift
    - Sources/App/entrypoint.swift
    - Sources/App/configure.swift
    - Sources/App/routes.swift
    - Sources/App/Models/Conference.swift
    - Sources/App/Models/Team.swift
    - Sources/App/Models/Player.swift
    - Sources/App/Models/Game.swift
    - Sources/App/Models/QuarterScore.swift
    - Sources/App/Models/GameStats.swift
    - Sources/App/Models/PlayerGameStats.swift
    - Sources/App/Migrations/CreateConference.swift
    - Sources/App/Migrations/CreateTeam.swift
    - Sources/App/Migrations/CreatePlayer.swift
    - Sources/App/Migrations/CreateGame.swift
    - Sources/App/Migrations/CreateQuarterScore.swift
    - Sources/App/Migrations/CreateGameStats.swift
    - Sources/App/Migrations/CreatePlayerGameStats.swift
    - Sources/App/Migrations/SeedConferences.swift
    - docker-compose.yml
    - .env.development
    - Dockerfile
  modified: []

key-decisions:
  - "Used SQLPostgresConfiguration with explicit variables instead of inline .init() to avoid Swift type-checker timeout"
  - "Used raw SQL via SQLKit for index creation (Fluent SchemaBuilder lacks index API)"
  - "Seeded conferences with nil StatBroadcast IDs (Plan 02 audit will discover actual IDs)"
  - "Used swift-tools-version:5.9 for compatibility with Dockerfile swift:5.9-jammy base"

patterns-established:
  - "Fluent models: final class conforming to Model, @unchecked Sendable with property wrappers"
  - "Migration naming: Create{ModelName} struct conforming to AsyncMigration"
  - "Database config: DATABASE_URL takes precedence over individual env vars"
  - "Seed migrations: separate migration struct for initial data population"

requirements-completed: [DATA-04]

# Metrics
duration: 6min
completed: 2026-02-24
---

# Phase 1 Plan 01: Vapor Project Scaffold Summary

**Vapor 4 project with 7 Fluent models covering full lacrosse game/player stat schema, PostgreSQL migrations, and 5 seeded conferences**

## Performance

- **Duration:** 6 min
- **Started:** 2026-02-25T04:26:17Z
- **Completed:** 2026-02-25T04:32:58Z
- **Tasks:** 2
- **Files modified:** 23

## Accomplishments

- Complete Vapor 4 project compiles with all 5 dependencies (Vapor, Fluent, FluentPostgresDriver, SwiftSoup, VaporCron)
- 7 Fluent models with full lacrosse stat coverage: Conference, Team, Player, Game, QuarterScore, GameStats, PlayerGameStats
- All model relationships wired: Conference->Teams, Team->Players, Game->QuarterScores, Game->PlayerGameStats with @Parent/@Children
- Migrations with proper foreign keys, cascading deletes, indexes on Game.startTime and Game.status, and unique constraints
- 5 Phase 1 conferences seeded: Big East, ACC, Big Ten, Patriot League, Ivy League
- Docker-compose for local PostgreSQL 16 and Dockerfile for Railway deployment

## Task Commits

Each task was committed atomically:

1. **Task 1: Create Vapor project scaffold with Package.swift and core infrastructure** - `3c7d98e` (feat)
2. **Task 2: Create all Fluent models, migrations, and conference seed data** - `d1a01d4` (feat)

## Files Created/Modified

- `Package.swift` - Swift package manifest with Vapor, Fluent, FluentPostgresDriver, SwiftSoup, VaporCron
- `Sources/App/entrypoint.swift` - Async @main entry point
- `Sources/App/configure.swift` - Database config (DATABASE_URL + fallback), migration registration, routes
- `Sources/App/routes.swift` - GET /health returning {"status": "ok"}
- `Sources/App/Models/Conference.swift` - Conference with statBroadcastID, ncaaID, children: teams
- `Sources/App/Models/Team.swift` - Team with wins/losses/ranking, parent: conference, children: players/games
- `Sources/App/Models/Player.swift` - Player with firstName/lastName/number/position, parent: team
- `Sources/App/Models/Game.swift` - Game with scores, status, period, clock, startTime, external IDs, parent: homeTeam/awayTeam
- `Sources/App/Models/QuarterScore.swift` - Quarter scoring breakdown, parent: game
- `Sources/App/Models/GameStats.swift` - Team-level game totals (all lacrosse stats), parent: game/team
- `Sources/App/Models/PlayerGameStats.swift` - Individual player stat line (optional fields for position-specific stats), parent: game/player
- `Sources/App/Migrations/Create*.swift` - 7 migrations with FK constraints, indexes, unique constraints
- `Sources/App/Migrations/SeedConferences.swift` - Seeds 5 Phase 1 conferences
- `docker-compose.yml` - PostgreSQL 16, port 5432, user vapor, db bardown
- `.env.development` - Local dev environment defaults
- `Dockerfile` - Multi-stage build (swift:5.9-jammy -> ubuntu:jammy), port 8080

## Decisions Made

- **SQLPostgresConfiguration explicit variables:** The inline `.init()` approach caused Swift type-checker timeout. Extracted to named variables for clearer type resolution.
- **Raw SQL for indexes:** Fluent's SchemaBuilder does not expose an `.index()` API. Used SQLKit raw SQL for creating indexes on games.start_time and games.status.
- **Nil StatBroadcast IDs in seed:** Conferences seeded without StatBroadcast IDs since actual IDs are unknown until the Plan 02 HTML audit.
- **Conference abbreviations:** Used BIGEAST, ACC, B1G, PATRIOT, IVY as internal abbreviations (actual StatBroadcast confid values TBD in Plan 02).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed Swift type-checker timeout in configure.swift**
- **Found during:** Task 1 (Project scaffold)
- **Issue:** Inline `SQLPostgresConfiguration.init()` with chained `Environment.get()` calls caused "unable to type-check this expression in reasonable time"
- **Fix:** Extracted each environment variable to a named local variable before passing to the configuration initializer
- **Files modified:** Sources/App/configure.swift
- **Verification:** `swift build` completes successfully
- **Committed in:** 3c7d98e (Task 1 commit)

**2. [Rule 3 - Blocking] Fixed Fluent SchemaBuilder lacking index API**
- **Found during:** Task 2 (Migrations)
- **Issue:** `database.schema("games").index(on: "start_time")` does not compile -- SchemaBuilder has no `.index()` member
- **Fix:** Used SQLKit raw SQL: `CREATE INDEX idx_games_start_time ON games (start_time)` and similar for status
- **Files modified:** Sources/App/Migrations/CreateGame.swift
- **Verification:** `swift build` completes successfully
- **Committed in:** d1a01d4 (Task 2 commit)

---

**Total deviations:** 2 auto-fixed (1 bug, 1 blocking)
**Impact on plan:** Both auto-fixes necessary for compilation. No scope creep.

## Issues Encountered

- Docker daemon not accessible from execution environment -- could not verify `docker compose up -d` or run migrations against a live database. The project compiles correctly and migrations are structurally sound. User should run `docker compose up -d && swift run App migrate --yes` to verify database creation.

## User Setup Required

None - no external service configuration required. To verify locally:
1. Start Docker Desktop
2. `docker compose up -d` (starts PostgreSQL)
3. `swift run App migrate --yes` (creates all tables and seeds conferences)
4. `swift run App serve` (starts server on port 8080)
5. `curl http://localhost:8080/health` (returns `{"status":"ok"}`)

## Next Phase Readiness

- All 7 data models are ready for Plan 02 (scraper pipeline) to populate with scraped data
- Conference seed data in place; Plan 02 will update StatBroadcast IDs after the HTML audit
- Database schema supports all lacrosse stats specified in requirements
- Plan 03 (API controllers + deployment) can build DTOs from these models

## Self-Check: PASSED

- All 22 created files verified present on disk
- Commit 3c7d98e (Task 1) verified in git log
- Commit d1a01d4 (Task 2) verified in git log
- `swift build` completes without errors

---
*Phase: 01-data-foundation*
*Completed: 2026-02-24*
