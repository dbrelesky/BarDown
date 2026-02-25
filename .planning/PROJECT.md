# BarDown

## What This Is

BarDown is a native SwiftUI iPhone and iPad app for men's Division 1 college lacrosse fans. It delivers live scores, full game detail (box scores, play-by-play, player stats), schedules, team rankings, and player leaderboards — all wrapped in Apple's Liquid Glass design language with a data-rich, dark-themed aesthetic built for passionate college-aged lacrosse fans. The college team logos are the visual heroes, and every interaction should feel as alive and exciting as the sport itself.

## Core Value

When a fan opens BarDown on game day, they instantly see every live D1 lacrosse score and can drill into any game for full, real-time detail — faster and more beautifully than any alternative.

## Requirements

### Validated

(None yet — ship to validate)

### Active

- [ ] Today's scoreboard as the default landing screen showing all D1 games (live, upcoming, final)
- [ ] Favorites system — onboarding team selection, favorites pinned to top everywhere
- [ ] Conference filtering alongside favorites
- [ ] Game detail view with full box score (quarter scores, shots, saves, faceoffs, ground balls, turnovers, penalties)
- [ ] Live play-by-play event feed within game detail
- [ ] Individual player stat lines within game detail
- [ ] Official school logos displayed prominently for every team/game
- [ ] Pre-game info: time, date, team rankings, location
- [ ] Horizontal date picker always visible on scoreboard for day-to-day navigation
- [ ] Full calendar sheet drill-down with monthly grid and game-day indicators
- [ ] Weekly poll rankings tracker with movement arrows and historical trends
- [ ] Player leaderboards — conference and national stat leaders (goals, assists, saves, faceoff %)
- [ ] Dark mode and light mode automatically set via OS preference
- [ ] Apple Liquid Glass design language throughout navigation chrome
- [ ] Cloud backend — server scrapes data on schedule, app pulls from our API
- [ ] Data scraping from StatBroadcast for schedules, live scores, box scores, player info
- [ ] NCAA API integration for supplementary data
- [ ] iPhone and iPad universal app

### Deferred to v2

- Push notifications — score alerts, upset alerts, final scores for favorited teams (see NOTF-01/02/03 in REQUIREMENTS.md)

### Out of Scope

- Social features (comments, sharing to in-app feed) — not core to v1 score-checking experience
- Video highlights or streaming — bandwidth/licensing complexity, defer to v2+
- Women's lacrosse — men's D1 focus for v1, expand later
- Android version — native iOS first
- In-app purchases or monetization — ship free, validate audience first
- Real-time chat — complexity not justified for v1

## Context

**Target Audience:** College student fans (18-22) who check scores between classes, follow rivals, live in group chats. The app sits next to ESPN, social apps, and group chats in their dock. Speed and data density are paramount.

**Design Philosophy:** Apple Design Award ambition. The app should feel like it was designed by Apple's UX team but with the energy and edge that resonates with teenage and college-aged users. Liquid Glass for navigation chrome only (tab bars, toolbars, sheets). Content is opaque, vibrant, logo-forward. Animations should feel twitchy and alive — not slow and corporate. Dark theme is the hero mode.

**UI Reference:** All design decisions must follow the Liquid Glass playbook in `UI-guidelines.md` — iOS 26+ targeting, `.glassEffect()` for navigation only, `GlassEffectContainer` for grouped controls, system tab bar/toolbar glass, content layer stays opaque and vivid.

**Data Sources:**
- StatBroadcast scoreboard: `https://stats.statbroadcast.com/scoreboard/index.html?confid=acc&theme=accgamecenter&confonly=1&sport=lcgame&gender=M&conflive=1`
- StatBroadcast in-game: `https://stats.statbroadcast.com/broadcast/?id=649161&confid=acc`
- NCAA API for supplementary schedule/ranking data
- Cloud backend scrapes and stores master database, app consumes our API

**Platform:** iOS 26+ / iPadOS 26+, SwiftUI App lifecycle, no UIKit. Xcode 26 project.

**Design References (from UI-guidelines.md):**
- WWDC25-219: Meet Liquid Glass
- WWDC25-356: Get to Know the New Design System
- WWDC25-323: Build a SwiftUI App with the New Design
- LiquidGlassReference (GitHub) for Claude context
- GlassKit design system pattern for reusable modifiers

## Constraints

- **Platform**: iOS 26+ minimum — Liquid Glass APIs require this baseline
- **Framework**: SwiftUI only — no UIKit, no hybrid
- **Data**: Independent scraping — no official partnerships, must handle rate limits and data freshness
- **First Milestone**: TestFlight to friends — working beta for feedback, not App Store submission
- **Design**: Must follow Apple's Liquid Glass conventions per UI-guidelines.md — glass on navigation chrome only, content stays opaque

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| SwiftUI-only, no UIKit | Liquid Glass is SwiftUI-first; UIKit adds complexity without benefit | — Pending |
| Cloud backend for data | Enables push notifications, shared state, scheduled scraping | — Pending |
| StatBroadcast as primary data source | Publicly accessible, covers all D1 conferences, real-time data | — Pending |
| Dark theme as hero mode | Matches audience preference, makes logos pop, creates premium feel | — Pending |
| iOS 26+ minimum deployment | Required for Liquid Glass APIs, acceptable for target audience | — Pending |
| Favorites + Conference dual filtering | Serves both casual and power users without overwhelming either | — Pending |

---
*Last updated: 2025-02-24 after initialization*
