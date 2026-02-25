# Roadmap: BarDown

## Overview

BarDown delivers live D1 lacrosse scores to fans faster and more beautifully than any alternative. The build order is backend-first: the scraping pipeline and API must exist before any iOS screen has real data to display. From there, the design system gets established once (GlassKit module), the scoreboard goes up as the core screen, favorites and game detail layer on top, and finally rankings and leaderboards complete the v1 TestFlight feature set. Every phase delivers a vertically complete capability that can be verified with real data.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [x] **Phase 1: Data Foundation** - Cloud backend scrapes StatBroadcast, stores master database, serves REST API
- [ ] **Phase 2: Design System & App Shell** - Xcode project, GlassKit module, tab navigation, universal iPhone/iPad app
- [ ] **Phase 3: Scoreboard** - Today's scores as the default landing screen with date navigation and team logos
- [ ] **Phase 4: Favorites & Teams** - Onboarding team picker, favorites pinned to top, conference filtering, team schedules
- [ ] **Phase 5: Game Detail** - Full box score, lacrosse-specific stats, individual player stat lines
- [ ] **Phase 6: Live Data & Play-by-Play** - Polling for live game updates, real-time play-by-play event feed
- [ ] **Phase 7: Rankings & Leaderboards** - Weekly poll rankings, conference standings, player stat leaders

## Phase Details

### Phase 1: Data Foundation
**Goal**: A deployed backend that scrapes StatBroadcast on schedule, stores structured game data in PostgreSQL, and serves clean REST JSON that the iOS app can consume
**Depends on**: Nothing (first phase)
**Requirements**: DATA-01, DATA-02, DATA-03, DATA-04, DATA-06
**Success Criteria** (what must be TRUE):
  1. Backend returns today's games as JSON from a single API endpoint, with correct scores for at least 5 Phase 1 conferences
  2. Backend returns a full box score (quarter scores, team stats, player stats) for a completed game via API
  3. Backend returns a team's season schedule via API
  4. App can fetch all data from the API without ever touching StatBroadcast directly
  5. Data is no more than 60 seconds stale for completed games (scrape schedule validated)
**Plans**: 5 plans

Plans:
- [x] 01-01-PLAN.md -- Vapor project scaffold, Fluent data models, migrations, local dev infrastructure
- [x] 01-02-PLAN.md -- StatBroadcast audit, scraper pipeline, NCAA API integration, smart scheduling
- [x] 01-03-PLAN.md -- REST API controllers, DTOs, Railway deployment (deployment deferred)
- [x] 01-04-PLAN.md -- Wire box score scraping into scheduler (gap closure)
- [x] 01-05-PLAN.md -- API security: API key authentication and rate limiting (gap closure, DATA-06)

### Phase 2: Design System & App Shell
**Goal**: An iOS 26 universal app with Liquid Glass navigation chrome, GlassKit design module, and tab-based structure ready to receive feature screens
**Depends on**: Phase 1
**Requirements**: DESG-01, DESG-02, DESG-03, DESG-04, DESG-05
**Success Criteria** (what must be TRUE):
  1. App launches on both iPhone and iPad with tab-based navigation using Liquid Glass tab bar
  2. GlassKit module exists and all glass effects are applied through it (no raw .glassEffect() calls in feature code)
  3. Dark mode is the default aesthetic; switching to light mode via OS preference produces a coherent light theme
  4. Content areas (where game cards, stats, and logos will live) are opaque and vivid, not glassed
**Plans**: 2 plans

Plans:
- [x] 02-01-PLAN.md -- Xcode project scaffold, GlassKit local Swift package, dark mode default, universal target
- [ ] 02-02-PLAN.md -- Tab navigation with Liquid Glass chrome, placeholder screens, glass audit script

### Phase 3: Scoreboard
**Goal**: Users open the app and instantly see every D1 lacrosse game for any date, with real scores, real logos, and smooth date navigation
**Depends on**: Phase 1, Phase 2
**Requirements**: SCOR-01, SCOR-02, SCOR-03, SCOR-04, SCOR-05, SCOR-06, SCOR-07, TEAM-05
**Success Criteria** (what must be TRUE):
  1. App launches directly to today's scoreboard showing all D1 games with live scores, upcoming start times, and final results
  2. Each game card displays both teams' official school logos, current score or start time, game status/period, and rankings when available
  3. User can swipe the horizontal date picker to see yesterday's and tomorrow's games without leaving the scoreboard
  4. User can open a monthly calendar sheet, tap any date, and jump directly to that day's games
  5. Scoreboard shows appropriate loading spinner, "No games today" empty state, and error state with retry
**Plans**: 7 plans

Plans:
- [ ] 03-01-PLAN.md — Backend: add GET /api/v1/games/dates endpoint to Vapor GameController
- [ ] 03-02-PLAN.md — Wave 0 TDD scaffolds: test fixtures + failing tests for GameModel, ViewModel, DateStrip
- [ ] 03-03-PLAN.md — iOS data layer: GameModel/TeamModel structs + APIClient networking service
- [ ] 03-04-PLAN.md — ScoreboardViewModel state machine + DateStripView + CalendarSheetView
- [ ] 03-05-PLAN.md — Game card components: GameCardView, TeamRowView, ScoreCenterView, LiveIndicator (Kingfisher)
- [ ] 03-06-PLAN.md — ScoreboardView composition: section grouping, pull-to-refresh, states, ScoreboardTab wired up
- [ ] 03-07-PLAN.md — Human verify: visual and functional sign-off on iOS simulator

### Phase 4: Favorites & Teams
**Goal**: Users pick their teams once, and those teams' games are always front and center across the app
**Depends on**: Phase 3
**Requirements**: TEAM-01, TEAM-02, TEAM-03, TEAM-04
**Success Criteria** (what must be TRUE):
  1. On first launch, user sees a team picker showing all D1 teams organized by conference, and selected teams persist across app launches
  2. Favorited teams' games appear pinned to the top of the scoreboard with visual distinction from other games
  3. User can filter the scoreboard to show only games from a selected conference
  4. User can navigate to a team view showing that team's full season schedule with results and upcoming games
**Plans**: TBD

Plans:
- [ ] 04-01: TBD

### Phase 5: Game Detail
**Goal**: Users can drill into any game and see the full statistical picture -- box score, team stats, and every player's line
**Depends on**: Phase 3
**Requirements**: GAME-01, GAME-02, GAME-03
**Success Criteria** (what must be TRUE):
  1. Tapping a game card opens a detail view showing quarter-by-quarter scoring breakdown and team stat totals
  2. Box score includes all lacrosse-specific stats: goals, assists, shots, saves, ground balls, faceoffs won/lost, turnovers, penalties
  3. User can scroll through individual player stat lines for both teams within the game detail view
**Plans**: TBD

Plans:
- [ ] 05-01: TBD

### Phase 6: Live Data & Play-by-Play
**Goal**: During live games, scores update automatically and users can follow the action through a real-time event feed
**Depends on**: Phase 1, Phase 5
**Requirements**: DATA-05, GAME-04
**Success Criteria** (what must be TRUE):
  1. When a game is live, the scoreboard and game detail view update scores automatically every 15-30 seconds without manual refresh
  2. Game detail view shows a chronological play-by-play feed with goals, assists, saves, and penalties as they happen
  3. Polling starts automatically when live games exist and stops when no games are in progress (battery-conscious)
**Plans**: TBD

Plans:
- [ ] 06-01: TBD

### Phase 7: Rankings & Leaderboards
**Goal**: Users can check who's ranked, who's rising, and who leads the nation in every stat category
**Depends on**: Phase 1, Phase 2
**Requirements**: RANK-01, RANK-02, RANK-03
**Success Criteria** (what must be TRUE):
  1. User can view the current weekly poll rankings with team name, rank, and movement indicators (up/down/new/dropped)
  2. User can view conference standings showing win-loss records for all teams in a conference
  3. User can view player leaderboards for goals, assists, saves, and faceoff percentage at both conference and national level
**Plans**: TBD

Plans:
- [ ] 07-01: TBD

## Progress

**Execution Order:**
Phases execute in numeric order: 1 -> 2 -> 3 -> 4/5 (parallel possible) -> 6 -> 7

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Data Foundation | 5/5 | Complete | 2026-02-25 |
| 2. Design System & App Shell | 1/2 | In progress | - |
| 3. Scoreboard | 3/7 | In Progress|  |
| 4. Favorites & Teams | 0/1 | Not started | - |
| 5. Game Detail | 0/1 | Not started | - |
| 6. Live Data & Play-by-Play | 0/1 | Not started | - |
| 7. Rankings & Leaderboards | 0/1 | Not started | - |
