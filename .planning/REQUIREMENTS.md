# Requirements: BarDown

**Defined:** 2026-02-24
**Core Value:** When a fan opens BarDown on game day, they instantly see every live D1 lacrosse score and can drill into any game for full, real-time detail — faster and more beautifully than any alternative.

## v1 Requirements

Requirements for TestFlight beta. Each maps to roadmap phases.

### Scoreboard

- [ ] **SCOR-01**: User sees all D1 lacrosse games for today (live, upcoming, final) immediately on app launch
- [ ] **SCOR-02**: Each game card shows both teams' official logos, score (or start time), period/status, and team rankings if available
- [ ] **SCOR-03**: Each game card shows team season records and national ranking when available
- [ ] **SCOR-04**: User can navigate between dates via horizontal date picker always visible at top
- [ ] **SCOR-05**: User can drill into full monthly calendar view to jump to any date
- [ ] **SCOR-06**: User can pull down to refresh scoreboard data
- [ ] **SCOR-07**: Scoreboard shows clear loading, empty ("no games today"), and error states

### Game Detail

- [ ] **GAME-01**: User can tap any game to see full box score (quarter-by-quarter scoring, team stats)
- [ ] **GAME-02**: Box score includes lacrosse-specific stats: goals, assists, shots, saves, ground balls, faceoffs, turnovers, penalties
- [ ] **GAME-03**: User can see individual player stat lines within game detail
- [ ] **GAME-04**: User can see live play-by-play event feed (goals, assists, saves, penalties as they happen)

### Teams & Favorites

- [ ] **TEAM-01**: User picks favorite teams during onboarding on first launch
- [ ] **TEAM-02**: Favorite teams' games are pinned to top of scoreboard and highlighted
- [ ] **TEAM-03**: User can filter scoreboard by conference
- [ ] **TEAM-04**: User can view per-team schedule ("when does my team play next?")
- [ ] **TEAM-05**: Official school logos displayed prominently in every game card and team view

### Rankings & Leaderboards

- [ ] **RANK-01**: User can view weekly poll rankings with movement arrows (up/down/new)
- [ ] **RANK-02**: User can view conference standings with W-L records
- [ ] **RANK-03**: User can view player leaderboards — conference and national stat leaders (goals, assists, saves, faceoff %)

### Design & Platform

- [ ] **DESG-01**: App uses Apple Liquid Glass design language for all navigation chrome (tab bar, toolbar, sheets)
- [ ] **DESG-02**: Content layer (game cards, stats, logos) is opaque and vivid — no glass on content
- [x] **DESG-03**: Dark mode is the hero aesthetic; light mode supported automatically via OS preference
- [x] **DESG-04**: App runs as universal iPhone + iPad app
- [x] **DESG-05**: GlassKit design system module centralizes all glass decisions for consistency

### Data & Backend

- [x] **DATA-01**: Cloud backend scrapes StatBroadcast on schedule for game data, starting with Phase 1 target conferences, expanding to all D1 by v1 completion
- [x] **DATA-02**: Backend serves clean REST JSON API consumed by the iOS app
- [x] **DATA-03**: App never directly accesses scraped sources — all data flows through our API
- [x] **DATA-04**: Backend stores master database of teams, players, schedules, and game results
- [ ] **DATA-05**: Live game data refreshes via polling (15-30 second intervals during live games)
- [x] **DATA-06**: API security — API key authentication for iOS client, rate limiting on all endpoints, no secrets stored in app binary

## v2 Requirements

Deferred to future release. Tracked but not in current roadmap.

### Notifications & Engagement

- **NOTF-01**: User receives push notifications for game start, final score, and score updates for favorited teams
- **NOTF-02**: User receives automatic upset alerts when unranked team beats ranked team
- **NOTF-03**: User can configure notification preferences per team

### Widgets & Live Activity

- **WIDG-01**: User can add Home Screen widget showing next game or live score for favorite team
- **WIDG-02**: User can add Lock Screen widget showing game status
- **WIDG-03**: User sees live score on Dynamic Island during active games

### Enhanced Content

- **ENHN-01**: User sees pre-game countdown cards with season records, last matchup, and rankings comparison
- **ENHN-02**: User can tap a player to see full season stat totals (not just today's line)
- **ENHN-03**: Women's D1 lacrosse coverage
- **ENHN-04**: iPad-optimized split-view / sidebar layout

## Out of Scope

| Feature | Reason |
|---------|--------|
| News / editorial content | BarDown is a data app, not a media company. Link out to Inside Lacrosse instead. |
| Social features (comments, reactions) | Moderation burden, small user base = ghost town. Users have group chats. |
| Video highlights / streaming | Licensing complexity and bandwidth costs. Link to ESPN+ streams. |
| Betting lines / odds | College athletes + betting is ethically murky. Under-21 audience. |
| Fantasy lacrosse | Market doesn't exist. Building it is building two products. |
| User accounts / login | Friction kills niche apps. Use iCloud sync for favorites instead. |
| Ads in v1 | Degrades premium feel. Validate audience first, monetize later. |
| Multi-sport support | Depth over breadth. The niche IS the product. |
| Real-time WebSocket for v1 | Polling every 15-30s is indistinguishable from "live." Simpler architecture. |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| SCOR-01 | Phase 3 | Pending |
| SCOR-02 | Phase 3 | Pending |
| SCOR-03 | Phase 3 | Pending |
| SCOR-04 | Phase 3 | Pending |
| SCOR-05 | Phase 3 | Pending |
| SCOR-06 | Phase 3 | Pending |
| SCOR-07 | Phase 3 | Pending |
| GAME-01 | Phase 5 | Pending |
| GAME-02 | Phase 5 | Pending |
| GAME-03 | Phase 5 | Pending |
| GAME-04 | Phase 6 | Pending |
| TEAM-01 | Phase 4 | Pending |
| TEAM-02 | Phase 4 | Pending |
| TEAM-03 | Phase 4 | Pending |
| TEAM-04 | Phase 4 | Pending |
| TEAM-05 | Phase 3 | Pending |
| RANK-01 | Phase 7 | Pending |
| RANK-02 | Phase 7 | Pending |
| RANK-03 | Phase 7 | Pending |
| DESG-01 | Phase 2 | Pending |
| DESG-02 | Phase 2 | Pending |
| DESG-03 | Phase 2 | Complete |
| DESG-04 | Phase 2 | Complete |
| DESG-05 | Phase 2 | Complete |
| DATA-01 | Phase 1 | Complete |
| DATA-02 | Phase 1 | Complete |
| DATA-03 | Phase 1 | Complete |
| DATA-04 | Phase 1 | Complete |
| DATA-05 | Phase 6 | Pending |
| DATA-06 | Phase 1 | Complete |

**Coverage:**
- v1 requirements: 30 total
- Mapped to phases: 30
- Unmapped: 0

---
*Requirements defined: 2026-02-24*
*Last updated: 2026-02-24 after roadmap creation*
