# Feature Research

**Domain:** Native iOS sports scores app — men's D1 college lacrosse niche
**Researched:** 2026-02-24
**Confidence:** MEDIUM (based on training data analysis of ESPN, CBS Sports, theScore, Sofascore, FotMob, Lacrosse Reference, and niche sports app patterns; no live source verification available)

## Feature Landscape

### Table Stakes (Users Expect These)

Features users assume exist. Missing any of these and the app feels broken — users will go back to ESPN or a browser.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| **Live scoreboard** | Every sports app opens to today's scores. ESPN, CBS, theScore all default to this. A scores app without a scoreboard is not a scores app. | MEDIUM | Requires reliable polling/push from backend. Must show live period, time remaining, score. Core of the app. |
| **Game detail / box score** | Tapping a game and seeing nothing is a dead end. ESPN shows full box scores for even niche sports. Users expect quarter-by-quarter scoring, team stats, and individual stat lines. | MEDIUM | Parsing StatBroadcast box score pages. Lacrosse-specific stats: goals, assists, shots, saves, GBs, faceoffs, turnovers, penalties. |
| **Date navigation** | Users check yesterday's scores and tomorrow's schedule constantly. Every major sports app has a horizontal date picker or swipe-to-navigate. | LOW | Horizontal date strip at top of scoreboard. Simple calendar sheet for jumping to distant dates. |
| **Team favorites** | ESPN, theScore, CBS all let you favorite teams and surface them first. College sports fans follow 1-3 teams obsessively. Without favorites, every session starts with scrolling. | LOW | Onboarding team picker, persist in UserDefaults/CloudKit. Pin favorites to top of scoreboard. |
| **Team schedules** | Fans want to see "when does my team play next?" Every sports app has a per-team schedule view. | LOW | Filtered view of master schedule data. Depends on scraping full season schedule from StatBroadcast. |
| **Standings / rankings** | D1 lacrosse fans follow weekly polls (Inside Lacrosse/USILA). ESPN and CBS show conference standings and poll rankings for every sport. | MEDIUM | Weekly poll data (Inside Lacrosse poll is the standard). Conference standings with W-L records. Need to source poll data reliably. |
| **Push notifications for favorites** | ESPN and theScore train users to expect score alerts. "Game started," "Final score," "upset alert" — these are table stakes for any sports scores app in 2026. | HIGH | Requires APNs, backend notification service, user preference management. Critical for retention but significant infrastructure. |
| **Dark mode support** | iOS users expect system appearance support. Every major app respects the system toggle. | LOW | SwiftUI handles most of this natively. Per PROJECT.md, dark is the hero mode. |
| **Pull-to-refresh** | Universal iOS pattern. Users pull down to get fresh data. Absence feels broken. | LOW | Standard SwiftUI `.refreshable` modifier. Triggers API call. |
| **Loading / empty / error states** | No data yet? Error? Off-season? Users need clear feedback, not blank screens or spinners that never resolve. | LOW | Skeleton views, empty state messaging ("No games today"), error retry prompts. |
| **Conference filtering** | D1 lacrosse has 10+ conferences. A scoreboard with 30+ games needs filtering. ESPN does this for every college sport. | LOW | Filter bar or segmented control on scoreboard. Pairs with favorites as the two primary filters. |

### Differentiators (Competitive Advantage)

Features that set BarDown apart from checking ESPN or a browser. These justify installing a dedicated niche app.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| **Lacrosse-first data density** | ESPN buries lacrosse 4 taps deep and shows minimal stats. BarDown opens directly to lacrosse with full box scores, faceoff stats, save percentages — data ESPN doesn't surface. The depth of a dedicated app vs. the breadth of a general one. | MEDIUM | Lacrosse-specific stat presentation (faceoff %, save %, shot clock violations). Not just generic sports stats — formatted for how lacrosse fans think. |
| **Live play-by-play feed** | Real-time event feed (goals, saves, penalties) within game detail. ESPN rarely provides this for lacrosse. Having it makes BarDown the only way to "follow along" without a stream. | HIGH | Depends on StatBroadcast providing play-by-play data in real-time. Parsing complexity is significant. Polling frequency matters. |
| **Player leaderboards** | National and conference stat leaders (goals, assists, points, saves, faceoff %). Lacrosse Reference has some of this but is a slow, desktop-first website. Mobile-native leaderboards are a gap. | MEDIUM | Requires aggregating player stats across all games. Backend computation. Conference and national filters. |
| **Instant game-day experience** | Zero-tap to live scores. App opens and you see what matters. No login wall, no news feed to scroll past, no ads covering content. ESPN's lacrosse path: Scores > More Sports > Lacrosse > Men's College. BarDown's path: Open app. | LOW | Architecture decision more than a feature. Default to scoreboard, favorites pinned. Onboarding is just "pick your teams." |
| **Upset alerts** | Automatic push when an unranked team is beating or has beaten a ranked team. No major app does this for lacrosse. Creates "watercooler moments" in group chats. | HIGH | Requires ranking data + score monitoring logic on backend. Depends on push notification infrastructure. High value, high complexity. |
| **Game countdown / pre-game cards** | Rich pre-game info: countdown timer, season records, last matchup result, ranking comparison. Makes the app useful even when no games are live. | LOW | Display layer on top of existing schedule data. No new data sources needed. |
| **Season stats within game context** | When viewing a game, tap a player to see their season totals — not just today's line. ESPN does this for major sports but not lacrosse. | MEDIUM | Requires player-level season stat aggregation in backend. Links game detail to player profiles. |
| **Widget support (iOS Lock Screen / Home Screen)** | Favorite team's next game or live score on Lock Screen. WidgetKit is well-supported in SwiftUI. Surfaces value without opening the app. College-aged users are heavy widget users. | MEDIUM | WidgetKit integration. Requires App Group for shared data. Small/medium/large + Lock Screen widget variants. Timeline provider for scheduled updates. |
| **Live Activity (Dynamic Island / Lock Screen)** | Live score on Dynamic Island during games. Apple's ActivityKit is purpose-built for this. The most "premium feel" feature possible for a scores app. | HIGH | ActivityKit integration. Requires backend push-to-update via APNs push tokens. Tight polling or push updates. iOS 16.1+ (well within iOS 26 target). |

### Anti-Features (Deliberately NOT Building)

Features that seem appealing but would hurt BarDown's focus, quality, or development timeline.

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| **News/editorial content** | ESPN and CBS bundle news with scores. Seems like it "completes" the experience. | Content creation is a full-time operation. Stale articles are worse than no articles. Pulls focus from data quality. BarDown is a data app, not a media company. | Link out to Inside Lacrosse or ESPN articles when relevant. Don't host content. |
| **Social features (comments, reactions, in-app sharing)** | Engagement metric darling. "Build community." | Moderation burden is enormous. College sports + anonymous comments = toxicity. Small user base means ghost-town feeds. Users already have group chats and Twitter/X. | Deep link sharing — tap "share" to send a game link to iMessage/group chat. Let social happen where it already lives. |
| **Video highlights / streaming** | "Complete game day experience." Users love video. | Licensing is expensive and legally complex. Bandwidth costs scale fast. NCAA/conference media rights are locked up. Building a video player is a product unto itself. | Link to ESPN+ or conference network streams. Surface "watch" links, don't build the player. |
| **Betting lines / odds integration** | Sports betting is massive. theScore pivoted entirely to betting. | Legal complexity across states. Audience is college-aged (many under 21). Associating college athletes with betting lines is ethically murky and increasingly regulated. Brand risk for a niche app. | Do not include. Not even "informational" odds. Clean separation from gambling. |
| **Fantasy lacrosse** | Fantasy drives engagement in NFL/NBA apps. | Fantasy lacrosse doesn't meaningfully exist as a market. Building it is building two products. Scoring systems, drafts, leagues, trades — massive scope. | Do not build. If fantasy lacrosse grows, it will be its own product. |
| **Women's lacrosse in v1** | "Why not both?" Doubles the addressable market. | Doubles data sources, scraping logic, UI surface area. Rules are different (field size, stick rules, scoring). Stat categories differ. Doing both mediocrely is worse than doing one well. | Build the architecture to support it later (abstract "sport" from "conference/team"). Ship men's D1 first, expand after validation. |
| **Multi-sport support** | "Add other college sports while you're at it." | Every sport has different stat models, data sources, and fan expectations. BarDown's value is depth, not breadth. ESPN already does breadth. | Stay single-sport. The niche IS the product. |
| **User accounts / login** | Needed for cross-device sync, "real" app feel. | Friction at onboarding kills niche apps. College-aged users won't create an account for a scores app. Adds auth infrastructure complexity. | Use iCloud/CloudKit for favorites sync. No account needed. Invisible sync. |
| **Ads in v1** | Revenue from day one. | College-aged users have near-zero ad tolerance. Ads in a niche app with small user base generate pennies. Degrades the premium feel that differentiates BarDown from ESPN. | Ship free, validate audience size first. Monetize later (if ever) through tasteful sponsorship or premium tier, not banner ads. |
| **Real-time WebSocket everything** | "Make it truly live — instant updates." | WebSocket infrastructure is complex to build and maintain. Polling every 15-30 seconds is indistinguishable from "live" for score updates. Adds backend complexity for marginal UX gain. | Smart polling (faster during live games, slower otherwise). Server-Sent Events if needed. WebSocket only if polling proves insufficient. |

## Feature Dependencies

```
[Cloud Backend API]
    ├──requires──> [Data Scraping Pipeline (StatBroadcast)]
    └──enables───> [Live Scoreboard]
                       ├──enables──> [Game Detail / Box Score]
                       │                 ├──enables──> [Play-by-Play Feed]
                       │                 └──enables──> [Player Stat Lines]
                       ├──enables──> [Date Navigation]
                       └──enables──> [Conference Filtering]

[Team Favorites]
    ├──enables──> [Favorites Pinning on Scoreboard]
    └──enables──> [Push Notifications for Favorites]
                       └──enables──> [Upset Alerts]

[Data Scraping Pipeline]
    ├──enables──> [Standings / Rankings]
    ├──enables──> [Team Schedules]
    └──enables──> [Player Leaderboards]
                       └──requires──> [Player Stat Aggregation (backend)]

[Push Notification Infrastructure]
    └──requires──> [Cloud Backend API]
    └──requires──> [APNs Setup]
    └──enables──> [Live Activity / Dynamic Island]

[Widget Support]
    └──requires──> [App Group shared data container]
    └──requires──> [Team Favorites] (to know which team to show)
```

### Dependency Notes

- **Everything requires the Cloud Backend + Scraping Pipeline:** No feature works without data. This is the critical-path foundation.
- **Push Notifications require backend infrastructure:** APNs token management, notification scheduling, and delivery logic all live server-side. Cannot be added as an afterthought.
- **Play-by-Play depends on StatBroadcast data availability:** If StatBroadcast doesn't expose play-by-play events in a parseable format, this feature may need to be descoped or deferred. Requires early validation.
- **Player Leaderboards require stat aggregation:** Not just displaying one game's stats — requires accumulating and ranking across all games. Backend computation job.
- **Upset Alerts require both Rankings data and Push infrastructure:** Two independent dependencies that must both exist.
- **Live Activity requires Push Notification infrastructure:** ActivityKit updates are delivered via APNs push tokens. Cannot exist without push being built first.
- **Widgets require App Groups:** Data sharing between main app and widget extension needs App Group container setup early in the project.

## MVP Definition

### Launch With (v1 — TestFlight Beta)

Minimum viable product to validate with friends. The question being answered: "Is this useful enough that I open it instead of ESPN?"

- [ ] **Live scoreboard** — The entire reason the app exists. Open app, see today's D1 lacrosse scores.
- [ ] **Date navigation** — Check yesterday's results, tomorrow's schedule. Horizontal date picker.
- [ ] **Game detail with box score** — Tap any game, see full stats. This is what ESPN doesn't do well for lacrosse.
- [ ] **Team favorites with onboarding** — Pick your teams on first launch, see them pinned to top.
- [ ] **Conference filtering** — Filter scoreboard by conference. Reduces noise on busy days.
- [ ] **Team schedule view** — "When does my team play next?" Basic filtered schedule.
- [ ] **Standings / poll rankings** — Weekly poll tracker with rankings and movement indicators.
- [ ] **Cloud backend + scraping pipeline** — The data engine. Everything else is a display layer on top of this.
- [ ] **Dark mode as default, light mode supported** — System appearance respected.
- [ ] **School logos** — Visual identity. Logos are the hero. Without them the app feels generic.

### Add After Validation (v1.x)

Features to layer in once the core loop is validated and users are retained.

- [ ] **Push notifications** — Score alerts and final score notifications for favorites. Trigger: users say "I forget to check the app."
- [ ] **Live play-by-play feed** — Real-time event stream in game detail. Trigger: StatBroadcast data validated as parseable for play-by-play.
- [ ] **Player leaderboards** — Conference and national stat leaders. Trigger: backend stat aggregation pipeline is stable.
- [ ] **Widget support** — Home Screen and Lock Screen widgets for next game / live score. Trigger: users want passive awareness without opening the app.
- [ ] **Game countdown / pre-game cards** — Rich pre-game info. Trigger: users open app before games and find it empty.

### Future Consideration (v2+)

Features to defer until product-market fit is established and user base is meaningful.

- [ ] **Live Activity / Dynamic Island** — Premium live score experience. Defer: requires mature push infrastructure and is complex to get right.
- [ ] **Upset alerts** — Smart notifications for upsets. Defer: requires ranking logic + push + monitoring. High value but high complexity.
- [ ] **Season player stats / profiles** — Tap a player to see season totals. Defer: requires significant backend data modeling.
- [ ] **Women's lacrosse** — Expand to women's D1. Defer: only after men's D1 is solid and architecture supports multi-sport.
- [ ] **iPad-optimized layout** — True split-view / sidebar layout for iPad. Defer: universal app runs on iPad from day one, but optimized layout is v2.

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| Live scoreboard | HIGH | MEDIUM | P1 |
| Game detail / box score | HIGH | MEDIUM | P1 |
| Date navigation | HIGH | LOW | P1 |
| Team favorites | HIGH | LOW | P1 |
| Conference filtering | MEDIUM | LOW | P1 |
| Team schedules | MEDIUM | LOW | P1 |
| Standings / rankings | MEDIUM | MEDIUM | P1 |
| School logos | HIGH | LOW | P1 |
| Dark/light mode | MEDIUM | LOW | P1 |
| Cloud backend + scraping | HIGH | HIGH | P1 |
| Pull-to-refresh | MEDIUM | LOW | P1 |
| Loading/empty/error states | MEDIUM | LOW | P1 |
| Push notifications | HIGH | HIGH | P2 |
| Live play-by-play | HIGH | HIGH | P2 |
| Player leaderboards | MEDIUM | MEDIUM | P2 |
| Widget support | MEDIUM | MEDIUM | P2 |
| Pre-game cards | LOW | LOW | P2 |
| Live Activity / Dynamic Island | HIGH | HIGH | P3 |
| Upset alerts | MEDIUM | HIGH | P3 |
| Player season profiles | MEDIUM | MEDIUM | P3 |

**Priority key:**
- P1: Must have for TestFlight beta launch
- P2: Add after core validation, before App Store launch
- P3: Future — requires proven audience and mature infrastructure

## Competitor Feature Analysis

| Feature | ESPN | theScore | CBS Sports | Lacrosse Reference | BarDown Approach |
|---------|------|----------|------------|-------------------|------------------|
| Lacrosse scores | Buried under "More Sports." Minimal stats. Often delayed. | Does not cover college lacrosse. | Minimal coverage, similar to ESPN. | No live scores. Historical data only. | Default landing screen. Full coverage. Zero taps. |
| Box scores | Basic: goals, assists for lacrosse. Missing faceoffs, GBs, detailed goalie stats. | N/A for lacrosse. | Similar to ESPN — bare minimum. | Has detailed historical box scores. Desktop-only. | Full lacrosse box score: every stat category, formatted for the sport. |
| Play-by-play | Rarely available for lacrosse. Sometimes for tournament games. | N/A for lacrosse. | Rarely available. | Not available. | Real-time event feed from StatBroadcast (if data supports it). |
| Push notifications | Available but lacrosse alerts are unreliable and often missing. | N/A for lacrosse. | Minimal lacrosse notification support. | No notifications. | Dedicated lacrosse alerts: game start, final, upsets. Reliable because it's all we do. |
| Favorites | Full favorites system across all sports. Works well. | Strong favorites UX. | Basic favorites. | No favorites. | Team-only favorites (simpler). Onboarding picker. Pinned to top of every view. |
| Rankings | Shows AP/Coaches poll when available. Not prominent for lacrosse. | N/A for lacrosse. | Similar to ESPN. | Historical rankings archive. | Weekly poll tracker with movement arrows, historical trend. Prominent placement. |
| Leaderboards | Generic stat leaders for major sports. Lacrosse leaders rare. | N/A for lacrosse. | Minimal. | Has some career/season leaders. Desktop. | Mobile-native lacrosse stat leaders. Conference and national. |
| Design quality | Cluttered. Ad-heavy. Lacrosse feels like an afterthought. | Clean but focused on betting now. | Ad-heavy. Functional, not beautiful. | Utilitarian. Data tables. Not mobile-optimized. | Liquid Glass, logo-forward, dark-first. Apple Design Award aspiration. Premium feel. |
| Load time to lacrosse | 4+ taps from app open. Scores > More > Lacrosse > Men's College. | Cannot get there. | 3-4 taps. Similar to ESPN. | N/A (website). Slow page loads. | 0 taps. Open app = lacrosse scores. |

## Sources

- ESPN iOS app feature analysis (training data, MEDIUM confidence — app features well-documented through 2025)
- theScore iOS app feature analysis (training data, MEDIUM confidence)
- CBS Sports iOS app feature analysis (training data, MEDIUM confidence)
- Lacrosse Reference website (training data, MEDIUM confidence — site structure and data availability)
- StatBroadcast scoreboard pages (referenced in PROJECT.md, direct URLs provided)
- Apple WidgetKit and ActivityKit documentation (training data, HIGH confidence — well-established APIs)
- General sports app UX patterns across FotMob, Sofascore, MLB At Bat, NHL app (training data, MEDIUM confidence — used to identify universal table-stakes patterns)

**Note:** WebSearch and WebFetch were unavailable during this research session. All findings are based on training data (cutoff ~mid-2025). Competitor feature sets may have changed. Confidence is MEDIUM across the board — recommend validating StatBroadcast data availability for play-by-play before committing to that feature.

---
*Feature research for: BarDown — men's D1 college lacrosse scores app*
*Researched: 2026-02-24*
