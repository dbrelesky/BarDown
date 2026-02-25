# Phase 3: Scoreboard - Context

**Gathered:** 2026-02-25
**Status:** Ready for planning

<domain>
## Phase Boundary

Users open the app and instantly see every D1 lacrosse game for any date, with real scores, real logos, and smooth date navigation. This is the default landing screen. Game detail drill-down (Phase 5), favorites/pinning (Phase 4), and live auto-refresh (Phase 6) are out of scope.

</domain>

<decisions>
## Implementation Decisions

### Game card layout
- Stacked card blocks: away team on top, home team on bottom (full-width cards)
- Keep cards lean vertically — no wasted space despite the stacked layout
- Large hero logos (~48-56pt) as the visual anchor for each team row
- Team identified by logo + 3-4 letter abbreviation (e.g., "SYR")
- Score displayed as a centered block between the two team rows (e.g., "7 - 3")
- Rich info density: season records (8-2), national ranking, venue name, and broadcast info when available
- No tap action on cards in this phase — view-only scoreboard

### Game state visual treatment
- **Live games:** Blinking red dot indicator, visual accent/glow to distinguish from other states
- **Final games:** "FINAL" label below score, winning team's row visually emphasized (bold name/score)
- **Upcoming games:** Start time + venue name displayed in the center block where score would be

### Date navigation
- Horizontal scrollable date strip at top — understated styling (not pill-shaped) to keep focus on content
- Only show dates that have games — no dead-end navigation to empty days
- Rolling window of approximately ±30 days from today
- Monthly calendar accessible as a bottom sheet overlay (half-sheet, slides up)
- Calendar sheet shows dot indicators under dates that have games
- Tap a date on calendar sheet to jump to that day's games and dismiss the sheet

### Score display & period info
- Live games show period + time remaining (e.g., "Q2 8:34") under the centered score
- Upcoming games show start time + venue in the center block

### Pull-to-refresh
- Custom animation: a single official NCAA white lacrosse ball bouncing with a shadow below reflecting realistic physics
- Not the default iOS spinner — this is a branded touch

### Game ordering & grouping
- Status-based sorting: live games first, then upcoming by start time, then final games
- Section headers separating groups: "LIVE", "UPCOMING", "FINAL"
- Final games collapse after approximately 3, with a "Show X more final games" button to expand
- Keeps user focus on live and upcoming action

### Empty state
- Empty goal app icon illustration
- Message: "Sorry folks, no ball scheduled today."
- Should rarely appear since date strip only shows dates with games

### Claude's Discretion
- Ranking badge/pill design and placement near team logos
- Exact card spacing, typography, and shadow treatment
- Loading skeleton/spinner design for initial data fetch
- Error state design and retry mechanism
- Section header styling
- Exact collapse threshold for final games
- Animation details for the date strip and calendar transitions

</decisions>

<specifics>
## Specific Ideas

- Live games get a blinking red dot — inspired by ESPN's live indicator treatment
- Centered score block between stacked teams — matchup-focused presentation, not traditional left-right scoreboard
- The bouncing lacrosse ball pull-to-refresh should feel physically realistic with proper shadow response
- Date strip should be subtle enough that game cards remain the hero content
- "Sorry folks, no ball scheduled today." — personality in the empty state without being cheesy

</specifics>

<deferred>
## Deferred Ideas

- Tapping a game card to open game detail — Phase 5
- Favorited teams pinned to top of scoreboard — Phase 4
- Conference filtering on scoreboard — Phase 4
- Live auto-refresh/polling for score updates — Phase 6

</deferred>

---

*Phase: 03-scoreboard*
*Context gathered: 2026-02-25*
