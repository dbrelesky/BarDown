# Pitfalls Research

**Domain:** Native iOS college lacrosse scores app with web scraping, live data, Liquid Glass design, cloud backend, push notifications
**Researched:** 2026-02-24
**Confidence:** MEDIUM (no web search available; based on training data, project context, and UI-guidelines.md)

## Critical Pitfalls

### Pitfall 1: Treating StatBroadcast HTML as a Stable API

**What goes wrong:**
StatBroadcast is not a documented API — it is a rendered HTML scoreboard page. The DOM structure, CSS class names, element IDs, and JavaScript-injected content can change at any time without notice. A mid-season HTML restructure breaks your entire data pipeline, and you discover it during a live game day when fans are watching.

**Why it happens:**
Developers build a scraper against the current HTML, ship it, and treat it as stable. StatBroadcast serves multiple conferences and sports, and they update their frontend regularly (new themes, layout tweaks, JavaScript rendering changes). They also use conference-specific themes (`theme=accgamecenter`) that may differ structurally from each other.

**How to avoid:**
- Build a scraping abstraction layer with per-conference parser adapters. Never couple your data model directly to HTML selectors.
- Use defensive parsing: if an expected element is missing, log the anomaly and degrade gracefully (show "data unavailable" rather than crash or show wrong data).
- Store raw HTML snapshots in your backend so you can replay and debug parser failures without waiting for the next live game.
- Build a health-check endpoint that validates scraper output against a schema before serving to clients.
- Monitor for structural changes weekly during off-season, daily during season.

**Warning signs:**
- Scraped fields returning `nil` or empty strings that previously had data.
- Game counts dropping (e.g., you see 3 games when the schedule says 8).
- Conference-specific pages working while others break (theme divergence).

**Phase to address:**
Phase 1 (Data Layer / Backend) — the parser architecture must be resilient from day one. Do not build UI until the data layer can survive structural changes.

---

### Pitfall 2: Polling Too Aggressively and Getting Rate-Limited or Blocked

**What goes wrong:**
To show "live" scores, you poll StatBroadcast frequently (every 5-15 seconds per game). Multiply by 20-40 concurrent D1 games on a busy Saturday, and your backend is hammering StatBroadcast with hundreds of requests per minute. StatBroadcast blocks your server IP, and your entire app goes dark during the busiest moment of the season.

**Why it happens:**
Developers optimize for data freshness without considering the source's perspective. StatBroadcast is a free scoreboard service for college athletics — they do not expect or welcome automated high-frequency scraping. There is no published rate limit, so you only discover the threshold by getting blocked.

**How to avoid:**
- Implement intelligent polling: scrape the master scoreboard page (one request) to get all scores, not individual game pages. Only hit individual game detail pages when a user actually opens that game.
- Use exponential backoff and jitter on retries.
- Cache aggressively on your backend — serve stale data with a "last updated X seconds ago" indicator rather than hammering the source.
- Rotate user agents and respect any `robots.txt` or rate signals.
- Build a fallback data source (NCAA API) so the app still functions if StatBroadcast blocks you.
- During off-season testing, use saved HTML fixtures instead of hitting live servers.

**Warning signs:**
- HTTP 429 or 403 responses from StatBroadcast.
- Increasing response latency from the source (they may throttle before blocking).
- Your cloud provider flagging unusually high outbound request volume.

**Phase to address:**
Phase 1 (Backend/Scraping) — rate limiting and caching strategy must be designed before any live scraping begins.

---

### Pitfall 3: JavaScript-Rendered Content That Server-Side Scraping Misses

**What goes wrong:**
StatBroadcast pages use JavaScript to dynamically load live score data, play-by-play events, and box score updates. A simple HTTP GET returns a shell HTML page with empty containers. Your scraper sees no game data because the actual content is rendered client-side via JavaScript after page load.

**Why it happens:**
Developers assume they can use a lightweight HTTP client (URLSession, Python requests) to fetch the page and parse HTML. This works for static pages but fails for JavaScript-heavy SPAs. StatBroadcast live pages (`/broadcast/?id=...`) specifically use JS-based real-time updates.

**How to avoid:**
- Investigate StatBroadcast's network traffic first. Use browser DevTools to identify the underlying XHR/fetch API calls that the JavaScript makes. Often the actual data comes from a JSON or XML endpoint that you can hit directly — bypassing the need for a headless browser entirely.
- If no direct data endpoints exist, use a headless browser (Puppeteer, Playwright) on your cloud backend to render the page and extract data.
- Never run headless browsers on the iOS client — this is a backend-only operation.
- Document which pages are static HTML vs. JS-rendered so you use the right scraping strategy for each.

**Warning signs:**
- Scraper returning empty arrays or null values for fields that clearly have data when viewed in a browser.
- HTML responses containing `<script>` tags with data-loading logic but no visible content in the body.
- Scores that never update even though games are live.

**Phase to address:**
Phase 1 (Backend/Scraping) — this must be validated during the first spike. Spend time in DevTools on actual StatBroadcast live game pages before writing any parser code.

---

### Pitfall 4: Liquid Glass on Content Layers (The "Blur Pile")

**What goes wrong:**
Developers apply `.glassEffect()` to score cards, game rows, player stat cells, or the main content area. The result is a visually muddy, unreadable interface where translucent layers stack on top of each other. Apple's HIG reviewers may flag this, and it objectively looks worse than opaque content.

**Why it happens:**
Liquid Glass is the exciting new thing. The instinct is to make everything glass to feel "modern." Additionally, AI code generators may scatter `.glassEffect()` on components where it doesn't belong because training data mixes navigation and content patterns.

**How to avoid:**
- Follow the rule from UI-guidelines.md verbatim: glass on navigation chrome only (tab bar, toolbar, sheets, floating action buttons). Content is opaque, vibrant, logo-forward.
- Build a `GlassKit` design system module in Phase 2 that centralizes all glass decisions. No direct `.glassEffect()` calls outside this module.
- Code review checklist item: "Is `.glassEffect()` only used on navigation elements?"
- Test with Reduce Transparency enabled — if content becomes unreadable, you have glass in the wrong places.

**Warning signs:**
- More than 5-6 `.glassEffect()` calls in the entire codebase (navigation elements are few).
- Any `.glassEffect()` inside a `List`, `ScrollView`, or `ForEach` body.
- Visual contrast issues in Xcode previews, especially with light backgrounds behind glass.

**Phase to address:**
Phase 2 (Design System / UI Foundation) — establish the GlassKit pattern before building any screens.

---

### Pitfall 5: Building the App Before Validating Data Availability

**What goes wrong:**
You design beautiful screens for box scores, play-by-play, player stats, and rankings — then discover that StatBroadcast doesn't provide some of these fields for certain conferences, or the NCAA API returns data in a completely different format than expected. You have UI that expects data that doesn't exist, requiring major redesigns.

**Why it happens:**
The natural impulse is to design the ideal UX first and figure out data later. But sports data is messy: not all conferences report the same stats, some games have incomplete data, and live feeds have different fields than post-game summaries.

**How to avoid:**
- Sprint zero: build a data audit. Scrape 10+ real games across 3+ conferences and catalog exactly which fields are available, which are missing, and which vary.
- Map every UI element to a specific data field and its availability percentage.
- Design the UI to gracefully degrade: if faceoff percentage isn't available, that cell says "N/A" or is hidden — not broken.
- Build mock data from real scraped data, not from idealized JSON you invented.

**Warning signs:**
- Mocks and designs show data fields you haven't verified exist in the source.
- Different conferences producing structurally different scraper outputs.
- "TBD" or placeholder fields in your data models.

**Phase to address:**
Phase 1 (Data Spike) — validate data availability before designing any UI. This should be the very first task.

---

### Pitfall 6: Push Notification Architecture That Doesn't Scale

**What goes wrong:**
You implement push notifications by checking score changes on the backend and sending APNs pushes for every score update in every game to every user who favorited that team. On a Saturday with 20 live games and 5,000 users, you're sending tens of thousands of pushes per minute. APNs throttles you, notifications arrive minutes late (defeating the purpose of "live" alerts), and your backend buckles under the notification fan-out load.

**Why it happens:**
APNs has undocumented rate limits per device token and per app. Developers test with 5 users and 1 game, and everything works. At scale, the system silently drops notifications or delivers them with significant delay. Apple explicitly warns against using push notifications for frequent content updates.

**How to avoid:**
- Use push notifications for high-signal events only: game start, game end, final scores, upset alerts (unranked beats ranked). NOT for every goal scored.
- For near-real-time score updates in-app, use a persistent connection (WebSocket or Server-Sent Events) from the app to your backend — not push notifications.
- Batch and deduplicate notifications on the backend before sending to APNs.
- Implement user-configurable notification preferences (every goal vs. final only vs. upsets only).
- Use APNs priority `.low` for non-urgent notifications and `.high` only for time-sensitive alerts.

**Warning signs:**
- Notification delivery latency exceeding 30 seconds during peak game times.
- APNs returning `429 TooManyRequests` or `410 Unregistered` errors at high rates.
- Users complaining about notification spam or missed notifications simultaneously.

**Phase to address:**
Phase 3 (Push Notifications) — but the architecture decision (push for alerts, WebSocket for live data) must be made in Phase 1 (Architecture).

---

### Pitfall 7: No Offline or Error State Design

**What goes wrong:**
The app shows a blank screen, spinner that never resolves, or crashes when the network is unavailable, the backend is down, or StatBroadcast is unreachable. College students are often on spotty campus Wi-Fi or in stadiums with poor cell service — exactly when they most want to check scores.

**Why it happens:**
Developers build the happy path first and treat errors as edge cases. In a live sports app, the "edge case" of degraded connectivity is actually a primary use case because users check scores in crowded stadiums.

**How to avoid:**
- Cache the last-known scoreboard state locally (SwiftData or simple JSON persistence). Show cached data with a "Last updated 2 min ago" badge when the network is unavailable.
- Design explicit error states for every screen: no network, backend down, no games today, scraper failure.
- Implement retry with exponential backoff and a manual "pull to refresh" as the user-initiated retry.
- Test in Airplane Mode and with Network Link Conditioner set to "Very Bad Network" regularly.

**Warning signs:**
- Any screen that shows only a `ProgressView()` with no timeout or error fallback.
- Absence of `.task` error handling in SwiftUI views.
- No local persistence layer in the data architecture.

**Phase to address:**
Phase 2 (App Shell / Core UI) — error states and caching should be built into the data layer from the start, not bolted on later.

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Hardcoded CSS selectors in scraper | Fast initial parsing | Breaks on any HTML change, requires redeployment | Never — use a selector config file at minimum |
| Storing scraped data as raw HTML blobs | No schema design needed | Impossible to query, massive storage, slow parsing on every read | Only for debug/replay storage alongside structured data |
| Single monolithic scraper function | Quick to build | Can't scale per-conference, can't isolate failures, can't test | Only for initial data spike (must refactor before Phase 2) |
| Skipping SwiftData/persistence for v1 | Less code, faster ship | No offline support, no caching, app feels broken on bad network | Never — even a simple JSON cache is mandatory |
| Using `Timer` for polling in SwiftUI | Simple live update mechanism | Battery drain, no backoff, continues when app is backgrounded | Only for prototyping — replace with server push before beta |
| Embedding API keys/URLs in client code | No backend needed for early testing | Secrets in the binary, App Store rejection risk | Only during local development, never in TestFlight builds |

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| StatBroadcast Scraping | Treating conference-specific pages as having identical structure | Build per-conference parser adapters; test with ACC, Big Ten, and Ivy League pages (different themes, different structures) |
| StatBroadcast Live Games | Using HTTP polling for live play-by-play | Inspect browser network tab — StatBroadcast may use WebSocket or long-polling internally; tap into that instead of re-scraping HTML |
| APNs Push Notifications | Sending to device tokens that have been invalidated | Process APNs feedback/response for `410 Unregistered` and prune tokens immediately; stale tokens waste quota |
| NCAA API | Assuming stable endpoints and response schemas | NCAA has historically changed or deprecated their public-facing data endpoints without notice; always have StatBroadcast as primary, NCAA as supplementary |
| College Team Logos | Bundling logos as local assets and forgetting licensing | Host logos on your CDN with a mechanism to update them; verify that using school logos is permissible (most schools publish brand guidelines with usage terms) |
| CloudKit / Cloud Backend | Assuming iCloud-based sync for shared data | CloudKit public databases have query limits and are not designed for high-frequency writes from a scraper; use a traditional backend (Supabase, Firebase, custom server) |

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| Rendering 50+ game cards simultaneously in a `ScrollView` with team logos | Choppy scrolling, high memory usage | Use `LazyVStack` with prefetch, downsample logo images, limit concurrent image decodes | 30+ simultaneous games on older iPhones (iPhone 12/13) |
| Liquid Glass effects on every visible element | GPU spikes, thermal throttling, battery drain | Restrict `.glassEffect()` to 3-5 navigation elements max, test with Instruments GPU profiler | Noticeable on any device when glass count exceeds ~8 concurrent elements |
| Polling all live game detail pages from the client | Network saturation, battery drain, cellular data usage | Server-side aggregation — client makes one API call, server does all scraping | More than 5 games live simultaneously |
| Storing full play-by-play history in memory | Memory pressure, app termination by iOS | Page play-by-play data, keep only current quarter in memory, load history on demand | Games with 100+ play-by-play events |
| Re-parsing dates/times on every render | UI stutter during scroll | Parse dates once in the data layer, store as `Date` objects, format with cached `DateFormatter` | Visible at 20+ game cards with countdown timers |

## Security Mistakes

| Mistake | Risk | Prevention |
|---------|------|------------|
| Backend scraping credentials or API keys in the iOS binary | Keys extracted via binary analysis; anyone can hit your backend directly | Use server-side authentication; iOS app authenticates to YOUR backend, which holds all scraping logic and external credentials |
| No authentication on your backend API | Anyone can scrape your aggregated data; potential abuse or DDoS | Implement API key or JWT auth even for v1; rate-limit per client |
| Logging full HTML responses in production | PII from StatBroadcast pages (player names, potentially more) ends up in cloud logs | Scrub or redact logs; only log metadata (response size, status code, parse success/failure) |
| Push notification token stored in plaintext on backend | Token leakage allows sending arbitrary pushes to your users | Encrypt at rest; limit access to the notification service only |

## UX Pitfalls

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| Showing a generic loading spinner with no context | User doesn't know if the app is broken or loading; abandons after 3 seconds | Show skeleton screens with team logo placeholders and "Loading scores..." text; animate immediately |
| Live score badge that says "LIVE" but data is 60+ seconds stale | User sees a "live" label but scores don't match what they're seeing on TV; destroys trust | Show "Updated 45s ago" instead of "LIVE" unless data is < 15 seconds old; be honest about freshness |
| Forcing favorite team selection before showing any content | User just wants to check scores NOW; friction before value | Show the full scoreboard immediately; prompt for favorites after first session or via a non-blocking banner |
| Identical visual treatment for live, upcoming, and final games | User can't quickly scan for the information state they care about | Use distinct visual hierarchy: live games have animated indicator + score emphasis; final games are subdued; upcoming show countdown |
| Small tap targets on game cards | Frustrating on one-handed iPhone use, especially while walking | Game cards should be full-width, minimum 60pt tall, entire card tappable — not just a small "Details" button |

## "Looks Done But Isn't" Checklist

- [ ] **Live Scores:** Data updates stop when the app is backgrounded for > 30 seconds — verify background refresh and reconnection logic
- [ ] **Push Notifications:** Works in development but fails in production because APNs environment (sandbox vs. production) wasn't switched in the backend
- [ ] **Scraper:** Works for today's games but breaks on the first day of conference tournaments because URL structure changes (`confonly=1` parameter behavior differs)
- [ ] **Dark Mode:** Looks great in dark mode but unreadable in light mode because colors were only tested against dark backgrounds
- [ ] **iPad Layout:** Compiles on iPad but shows a stretched iPhone layout — verify adaptive layouts with `NavigationSplitView` for iPad
- [ ] **Favorites:** Stored locally but lost on app reinstall — sync favorites to iCloud KeyValue store or your backend
- [ ] **Date Picker:** Works for today but doesn't handle timezone correctly — a West Coast game at 10 PM ET shows as the wrong day for Pacific time users
- [ ] **Rankings:** Hardcoded to current week's poll — verify it handles preseason, mid-season, and postseason poll states (some weeks have no poll)
- [ ] **Team Logos:** Displays correctly for Power 5 conferences but missing/broken for smaller programs — verify all D1 teams have assets

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| StatBroadcast HTML structure changes | MEDIUM | Swap parser adapter for affected conference; replay stored HTML snapshots to validate; deploy backend hotfix (no app update needed since parsing is server-side) |
| Rate-limited/blocked by StatBroadcast | HIGH | Rotate to backup IP/proxy; reduce polling frequency; add NCAA API as fallback data source; negotiate access if possible |
| Glass on content layers (visual mess) | LOW | Remove `.glassEffect()` from content views; centralize into GlassKit module; 1-2 day refactor |
| Push notification throttling at scale | MEDIUM | Switch to event-based pushes (final scores only); implement WebSocket for in-app live updates; rewrite notification fan-out logic |
| No offline/error states | MEDIUM | Add SwiftData cache layer; design and implement error state views for each screen; 3-5 day effort if retrofitting |
| Data model doesn't match actual scraped data | HIGH | Audit all data sources; redesign data models; update every view that consumes the data; potential 1-2 week setback |

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| StatBroadcast HTML instability | Phase 1 (Data Spike) | Parser adapter architecture documented; raw HTML snapshot storage working; health-check endpoint validates output |
| Rate limiting / IP blocking | Phase 1 (Backend) | Rate limit config in place; request logs show < 2 req/sec to StatBroadcast; fallback data source functional |
| JS-rendered content missed | Phase 1 (Data Spike) | Network traffic analysis documented; XHR/API endpoints identified or headless browser deployed |
| Liquid Glass on content | Phase 2 (Design System) | GlassKit module exists; code review confirms zero `.glassEffect()` on content layers |
| Data availability gaps | Phase 1 (Data Audit) | Data availability matrix covers all D1 conferences; UI designs annotated with data source for each field |
| Push notification architecture | Phase 1 (Architecture) + Phase 3 (Implementation) | Architecture doc specifies push vs. WebSocket boundary; load test with simulated 20-game Saturday |
| No offline/error states | Phase 2 (Core UI) | Every screen has error/empty/loading/offline states in Xcode previews; tested with Airplane Mode |
| Stale "LIVE" indicator | Phase 2 (Core UI) | Data freshness timestamp displayed; "LIVE" label gated on < 15s data age |
| iPad layout not adaptive | Phase 2 (Core UI) | `NavigationSplitView` used for iPad; tested on iPad simulator at multiple sizes |
| Timezone handling for game times | Phase 1 (Data Model) | All times stored as UTC `Date`; display formatted with user's local timezone; tested with device set to PT, CT, ET |

## Sources

- Apple WWDC25-219: Meet Liquid Glass (design constraints, where glass belongs)
- Apple WWDC25-356: Get to Know the New Design System (navigation vs. content hierarchy)
- Apple WWDC25-323: Build a SwiftUI App with the New Design (implementation patterns)
- UI-guidelines.md (project-specific Liquid Glass playbook — comprehensive pitfalls section)
- PROJECT.md (BarDown project requirements, constraints, data sources)
- Apple APNs documentation (rate limiting behavior, priority levels, feedback service)
- StatBroadcast scoreboard URLs (inspected structure patterns from PROJECT.md)
- General training data on sports data scraping, SwiftUI performance, and push notification architecture (MEDIUM confidence — not web-verified for this session)

---
*Pitfalls research for: BarDown — native iOS college lacrosse scores app*
*Researched: 2026-02-24*
