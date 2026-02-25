# Phase 1: Data Foundation - Context

**Gathered:** 2026-02-24
**Status:** Ready for planning

<domain>
## Phase Boundary

A deployed cloud backend that scrapes StatBroadcast on a schedule, stores structured game data in PostgreSQL, and serves clean REST JSON that the iOS app can consume. Covers requirements DATA-01 through DATA-04. Live polling (DATA-05) is Phase 6.

</domain>

<decisions>
## Implementation Decisions

### Scraping strategy
- Scrape every 30-60 seconds during live games for near real-time scores
- Phase 1 conferences: Big East, ACC, Big Ten, Patriot League, Ivy League
- Remaining D1 conferences added in a follow-up (not this phase)
- On scrape failure: retry a few times, then serve last successful data — API stays up even when scraping is broken
- Claude to investigate StatBroadcast page structure and determine URL patterns, parsing approach

### Data model shape
- Store both team-level totals AND individual player stat lines from day one (ready for Phase 5: Game Detail)
- Lacrosse stats to capture: goals, assists, shots, saves, ground balls, faceoffs won/lost, turnovers, penalties
- Current 2026 season only — no historical seasons in v1 schema
- Quarter-by-quarter scoring breakdown stored per game

### Hosting & infrastructure
- Budget: $10-25/month for all backend services
- Claude picks the runtime, platform, and architecture based on what fits a scraping service + REST API + managed Postgres within budget

### Locked Decisions
- Backend language/runtime: Swift (Vapor 4) — shared-Swift monorepo with iOS client

### Claude's Discretion
- Team identification strategy (internal IDs vs StatBroadcast IDs vs hybrid)
- Logo sourcing approach (bundled in app vs served from API/CDN)
- Cloud provider and deployment platform selection
- Whether scraper and API are one service or separate deployments
- Scrape scheduling logic (smart scheduling based on game times vs fixed intervals)
- Database ORM and migration tooling

</decisions>

<specifics>
## Specific Ideas

- User has browsed StatBroadcast casually but hasn't studied the HTML/URL structure — researcher needs to investigate this thoroughly
- Success criteria requires data no more than 60 seconds stale for completed games, which aligns with the 30-60s scrape frequency
- API must serve: today's games, full box scores (quarter scores + team stats + player stats), and team season schedules

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 01-data-foundation*
*Context gathered: 2026-02-24*
