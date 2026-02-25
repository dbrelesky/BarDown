# Phase 3: Scoreboard - Research

**Researched:** 2026-02-25
**Domain:** SwiftUI data networking, async image loading, horizontal date navigation, bottom sheet calendar, custom animations
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Game card layout**
- Stacked card blocks: away team on top, home team on bottom (full-width cards)
- Keep cards lean vertically — no wasted space despite the stacked layout
- Large hero logos (~48-56pt) as the visual anchor for each team row
- Team identified by logo + 3-4 letter abbreviation (e.g., "SYR")
- Score displayed as a centered block between the two team rows (e.g., "7 - 3")
- Rich info density: season records (8-2), national ranking, venue name, and broadcast info when available
- No tap action on cards in this phase — view-only scoreboard

**Game state visual treatment**
- Live games: Blinking red dot indicator, visual accent/glow to distinguish from other states
- Final games: "FINAL" label below score, winning team's row visually emphasized (bold name/score)
- Upcoming games: Start time + venue name displayed in the center block where score would be

**Date navigation**
- Horizontal scrollable date strip at top — understated styling (not pill-shaped) to keep focus on content
- Only show dates that have games — no dead-end navigation to empty days
- Rolling window of approximately ±30 days from today
- Monthly calendar accessible as a bottom sheet overlay (half-sheet, slides up)
- Calendar sheet shows dot indicators under dates that have games
- Tap a date on calendar sheet to jump to that day's games and dismiss the sheet

**Score display & period info**
- Live games show period + time remaining (e.g., "Q2 8:34") under the centered score
- Upcoming games show start time + venue in the center block

**Pull-to-refresh**
- Custom animation: a single official NCAA white lacrosse ball bouncing with a shadow below reflecting realistic physics
- Not the default iOS spinner — this is a branded touch

**Game ordering & grouping**
- Status-based sorting: live games first, then upcoming by start time, then final games
- Section headers separating groups: "LIVE", "UPCOMING", "FINAL"
- Final games collapse after approximately 3, with a "Show X more final games" button to expand
- Keeps user focus on live and upcoming action

**Empty state**
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

### Deferred Ideas (OUT OF SCOPE)
- Tapping a game card to open game detail — Phase 5
- Favorited teams pinned to top of scoreboard — Phase 4
- Conference filtering on scoreboard — Phase 4
- Live auto-refresh/polling for score updates — Phase 6
</user_constraints>

---

## Summary

Phase 3 is the first feature phase for the iOS client. It transforms ScoreboardTab.swift from a placeholder with fake cards into a fully functional, data-driven scoreboard. The work has three distinct layers: (1) a networking layer that calls the backend API (`GET /api/v1/games/today` and `GET /api/v1/games/date/:date`) and decodes the `GameResponse` JSON into Swift model structs, (2) a date navigation layer with a horizontal scrollable strip and a bottom sheet monthly calendar, and (3) the game card UI that renders team logos, scores, game state, and section grouping with expand/collapse.

The backend API is already complete from Phase 1 and serves exactly the data this phase needs. `GameResponse` includes `homeTeam`, `awayTeam` (each as `TeamBrief` with `name`, `abbreviation`, `record`, `ranking`, and `logoAssetName`), `homeScore`, `awayScore`, `status` (scheduled/live/final), `period`, `clock`, and `startTime`. The iOS app will mirror these as local `Decodable` structs — no shared package needed for v1.

The most technically nuanced areas are: (a) the custom pull-to-refresh animation (bouncing lacrosse ball), which requires a custom implementation rather than the standard `.refreshable` spinner; (b) image caching for team logos (AsyncImage does NOT cache — use Kingfisher or a URLCache-backed approach); and (c) the date-only API (`GET /api/v1/games/date/:date`) needs the app to fetch available game dates for the ±30 day window, which the current API does not expose as an index. The planner must decide whether to add a `/api/v1/games/dates` endpoint to the backend or compute dates client-side from a broader date range fetch.

**Primary recommendation:** Use the `@Observable` macro (Swift 6.2 / iOS 17+) for the `ScoreboardViewModel`, `.task(id:)` modifier for re-fetching on date change, Kingfisher for logo caching, a `ScrollViewReader`-wrapped `LazyHStack` for the date strip, `presentationDetents([.medium])` for the calendar sheet, and a custom `PreferenceKey`-based pull offset detector for the branded lacrosse ball refresh animation.

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| SCOR-01 | User sees all D1 lacrosse games for today (live, upcoming, final) immediately on app launch | `GET /api/v1/games/today` backend endpoint exists. iOS needs `ScoreboardViewModel` + `.task` modifier to fetch on view appear. Decode into local `GameModel` structs. |
| SCOR-02 | Each game card shows both teams' official logos, score (or start time), period/status, and team rankings if available | `TeamBrief` DTO provides `logoAssetName`, `abbreviation`, `ranking`, `record`. Card layout: stacked away/home rows with centered score block. Logo via Kingfisher from URL or local asset. |
| SCOR-03 | Each game card shows team season records and national ranking when available | `TeamBrief.record` (e.g., "8-2") and `TeamBrief.ranking` (optional Int) are in API response. Ranking badge rendered as pill near team row. |
| SCOR-04 | User can navigate between dates via horizontal date picker always visible at top | `ScrollViewReader` + `LazyHStack` date strip. Tapping a date sets `selectedDate` in ViewModel, triggering `.task(id: selectedDate)` re-fetch via `GET /api/v1/games/date/:date`. |
| SCOR-05 | User can drill into full monthly calendar view to jump to any date | `.sheet()` with `presentationDetents([.medium])` presenting a `DatePicker`-style calendar grid. Dot indicators on game dates. Tapping a date sets selectedDate and dismisses sheet. |
| SCOR-06 | User can pull down to refresh scoreboard data | Custom pull-to-refresh using `PreferenceKey` offset detection + `@State isRefreshing`. Custom bouncing lacrosse ball animation shown during refresh. Cannot use native `.refreshable` spinner alone — needs custom indicator layer. |
| SCOR-07 | Scoreboard shows clear loading, empty ("no games today"), and error states | Three states in ViewModel: `.loading`, `.empty`, `.error(String)`, `.loaded([GameModel])`. Loading: skeleton card shimmer via `.redacted(reason: .placeholder)`. Empty: illustration + "Sorry folks, no ball scheduled today." Error: message + retry button. |
| TEAM-05 | Official school logos displayed prominently in every game card and team view | Logos served via `logoAssetName` field — either a local asset name (bundled) or a URL string. Kingfisher's `KFImage` handles URL logos with disk+memory cache. Local asset fallback for offline. |
</phase_requirements>

---

## Standard Stack

### Core
| Library/API | Version | Purpose | Why Standard |
|-------------|---------|---------|--------------|
| SwiftUI | iOS 26 (deployed) | All UI — game cards, date strip, calendar sheet, animations | Already in use; phase 2 established patterns |
| Swift 6.2 | Xcode 26 | Language — `@Observable`, structured concurrency, `@MainActor` | Already locked in project.yml |
| `@Observable` macro | Swift 5.9+ / iOS 17+ | ViewModel state — replaces `ObservableObject` | More efficient invalidation, less boilerplate; iOS 26 target makes this available |
| URLSession async/await | iOS 15+ | HTTP calls to backend REST API | Native, no dependencies; `data(from:)` returns `(Data, URLResponse)` |
| Kingfisher | 8.x | Team logo image loading + disk/memory caching | Industry-standard; `KFImage` matches `AsyncImage` API; avoids re-fetch flicker that native `AsyncImage` has |

### Supporting
| Library/API | Version | Purpose | When to Use |
|-------------|---------|---------|-------------|
| `ScrollViewReader` | iOS 14+ | Programmatic scroll to selected date in strip | Wrap the `LazyHStack` date strip; call `.scrollTo(selectedDate, anchor: .center)` on selection |
| `presentationDetents` | iOS 16+ | Half-sheet for monthly calendar | `.sheet()` with `.presentationDetents([.medium])` on the calendar overlay |
| `.task(id:)` modifier | iOS 15+ | Re-fetch data when `selectedDate` changes | Better than `onAppear` + `onChange` combo; auto-cancels previous task |
| `.redacted(reason: .placeholder)` | iOS 14+ | Skeleton loading state for game cards | One-line shimmer placeholder that matches the card shape |
| `PreferenceKey` + `GeometryReader` | iOS 14+ | Detect scroll offset for custom pull-to-refresh | Needed because native `.refreshable` spinner cannot be replaced with custom view |
| `withAnimation(.spring())` | iOS 13+ | Date strip selection animation, section expand/collapse | Use `.bouncy` or `.spring` for natural feel |
| `withRepeatForever` + opacity | iOS 13+ | Blinking red dot live indicator | `Animation.easeInOut(duration: 0.8).repeatForever(autoreverses: true)` on opacity |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Kingfisher | Native `AsyncImage` | `AsyncImage` does NOT cache between view loads — logos re-fetch on every scroll. Kingfisher provides disk+memory cache with identical `KFImage` API |
| Kingfisher | `CachedAsyncImage` (lorenzofiamingo) | Lightweight alternative; same API as `AsyncImage`; but Kingfisher is more battle-tested with advanced cache controls |
| `@Observable` | `ObservableObject` + `@StateObject` | `ObservableObject` triggers full-view re-renders on any `@Published` change; `@Observable` only invalidates views that read changed properties — better for scoreboard with many fields |
| Custom pull-to-refresh | Native `.refreshable` | `.refreshable` cannot replace the default spinner with a custom animation; must build a scroll-offset detector and own animation layer |
| `presentationDetents` half-sheet | Full-screen `.sheet()` | Full sheet is too aggressive for a date picker — half-sheet keeps scoreboard context visible |

**Installation:**
```bash
# In BarDown-iOS/BarDown.xcodeproj, add via Xcode SPM:
# Kingfisher: https://github.com/onevcat/Kingfisher.git  ~> 8.0
```

Or add to project.yml:
```yaml
packages:
  Kingfisher:
    url: https://github.com/onevcat/Kingfisher.git
    minorVersion: "8.0.0"
```

---

## Architecture Patterns

### Recommended Project Structure
```
BarDown-iOS/BarDown/
├── Tabs/
│   └── ScoreboardTab.swift           # Entry point view (already exists — replace placeholder)
├── Features/
│   └── Scoreboard/
│       ├── ScoreboardViewModel.swift  # @Observable VM — fetching, state, date selection
│       ├── ScoreboardView.swift       # Main list with section grouping and states
│       ├── GameCardView.swift         # Single game card (away/home stacked layout)
│       ├── TeamRowView.swift          # One team row: logo + abbreviation + record + ranking
│       ├── ScoreCenterView.swift      # Centered block: score or start time, period/clock
│       ├── DateStripView.swift        # Horizontal scrollable date selector
│       ├── CalendarSheetView.swift    # Half-sheet monthly calendar with dot indicators
│       ├── PullToRefreshView.swift    # Bouncing lacrosse ball animation view
│       └── ScoreboardStates.swift    # LoadingView, EmptyView, ErrorView
├── Networking/
│   ├── APIClient.swift               # URLSession wrapper — base URL, API key header, decode
│   └── GameEndpoint.swift            # Endpoint definitions: /games/today, /games/date/:date
└── Models/
    ├── GameModel.swift               # Local Decodable mirror of GameResponse DTO
    └── TeamModel.swift               # Local Decodable mirror of TeamBrief DTO
```

### Pattern 1: @Observable ViewModel with .task(id:) Re-fetch
**What:** `ScoreboardViewModel` marked `@Observable` holds loading state, game data, and selected date. The view uses `.task(id: viewModel.selectedDate)` to automatically re-fetch whenever the date changes. Task is auto-cancelled when the view disappears or date changes.
**When to use:** Any data-driven view that needs to reload on a changing parameter.
**Example:**
```swift
// Source: Apple Observation framework docs + Swift 6.2 concurrency guide
import Observation

@Observable
@MainActor
final class ScoreboardViewModel {
    enum State {
        case loading
        case loaded([GameModel])
        case empty
        case error(String)
    }

    var state: State = .loading
    var selectedDate: Date = Calendar.current.startOfDay(for: .now)
    var isRefreshing: Bool = false

    private let apiClient: APIClient

    init(apiClient: APIClient = .shared) {
        self.apiClient = apiClient
    }

    func loadGames(for date: Date) async {
        state = .loading
        do {
            let games = try await apiClient.fetchGames(for: date)
            state = games.isEmpty ? .empty : .loaded(games)
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    func refresh() async {
        isRefreshing = true
        await loadGames(for: selectedDate)
        isRefreshing = false
    }
}

// In ScoreboardView:
struct ScoreboardView: View {
    @State private var viewModel = ScoreboardViewModel()

    var body: some View {
        // ...
        .task(id: viewModel.selectedDate) {
            await viewModel.loadGames(for: viewModel.selectedDate)
        }
    }
}
```

### Pattern 2: Networking Service Layer
**What:** `APIClient` encapsulates URLSession, base URL construction, API key header injection, and JSON decoding. `GameEndpoint` defines the two endpoints needed.
**When to use:** All network calls go through `APIClient` — never call URLSession directly from a ViewModel.
**Example:**
```swift
// Source: Modern iOS networking best practices, SwiftLee, avanderlee.com
struct APIClient {
    static let shared = APIClient()
    private let session: URLSession
    private let baseURL = URL(string: "https://your-backend.railway.app")!
    private let apiKey = "your-api-key" // from secure config / Info.plist

    func fetchGames(for date: Date) async throws -> [GameModel] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: date)

        let url = baseURL.appendingPathComponent("/api/v1/games/date/\(dateString)")
        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "X-API-Key")

        let (data, _) = try await session.data(for: request)
        return try JSONDecoder().decode([GameModel].self, from: data)
    }
}
```

### Pattern 3: Horizontal Date Strip with ScrollViewReader
**What:** `LazyHStack` of date items inside `ScrollView(.horizontal)` wrapped in `ScrollViewReader`. On appear, scroll to today. On date selection, update `selectedDate` in ViewModel and scroll to center.
**When to use:** Horizontal date navigation with programmatic position control.
**Example:**
```swift
// Source: Apple ScrollViewReader docs, hackingwithswift.com examples
struct DateStripView: View {
    @Bindable var viewModel: ScoreboardViewModel
    let gameDates: [Date]  // only dates that have games

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 16) {
                    ForEach(gameDates, id: \.self) { date in
                        DateCell(date: date, isSelected: viewModel.selectedDate == date)
                            .id(date)
                            .onTapGesture {
                                withAnimation(.spring(duration: 0.3)) {
                                    viewModel.selectedDate = date
                                    proxy.scrollTo(date, anchor: .center)
                                }
                            }
                    }
                }
                .padding(.horizontal)
            }
            .onAppear {
                proxy.scrollTo(viewModel.selectedDate, anchor: .center)
            }
        }
    }
}
```

### Pattern 4: Custom Pull-to-Refresh
**What:** Track scroll offset via `PreferenceKey` + `GeometryReader`. When offset exceeds a threshold, trigger refresh. Show custom lacrosse ball animation during pull and refresh phases. The native `.refreshable` spinner is NOT used — it cannot be visually replaced.
**When to use:** Required here because CONTEXT.md locks the branded lacrosse ball animation.
**Example:**
```swift
// Source: SwiftUI Lab pull-to-refresh pattern, Level Up Coding Nov 2025
struct ScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// Inside ScrollView content, attach a GeometryReader anchor at the top:
GeometryReader { geo in
    Color.clear.preference(
        key: ScrollOffsetKey.self,
        value: geo.frame(in: .named("scroll")).minY
    )
}
.frame(height: 0)

// Parent listens via .onPreferenceChange(ScrollOffsetKey.self) { offset in ... }
// When offset > threshold and not already refreshing, trigger viewModel.refresh()
```

### Pattern 5: Blinking Live Indicator
**What:** A red `Circle` whose opacity alternates between 0.3 and 1.0 using `.repeatForever` animation. Applied only when game status is "live".
**When to use:** On any game card where `game.status == "live"`.
**Example:**
```swift
// Source: SwiftUI animation documentation, canopas.com examples
struct LiveIndicator: View {
    @State private var isBlinking = false

    var body: some View {
        Circle()
            .fill(Color.red)
            .frame(width: 8, height: 8)
            .opacity(isBlinking ? 0.3 : 1.0)
            .animation(
                .easeInOut(duration: 0.8).repeatForever(autoreverses: true),
                value: isBlinking
            )
            .onAppear { isBlinking = true }
    }
}
```

### Pattern 6: Collapsible Final Games Section
**What:** Track a `showAllFinals: Bool` state variable. If false, only show the first N final games (3) plus a "Show X more" button. Toggling expands to full list.
**When to use:** Final games section in the sorted scoreboard list.
**Example:**
```swift
// Source: SwiftUI section/DisclosureGroup patterns
@State private var showAllFinals = false
let finalGames: [GameModel] = // ...
let collapseThreshold = 3

var displayedFinals: [GameModel] {
    showAllFinals ? finalGames : Array(finalGames.prefix(collapseThreshold))
}

// In the view body:
ForEach(displayedFinals) { game in GameCardView(game: game) }
if finalGames.count > collapseThreshold && !showAllFinals {
    Button("Show \(finalGames.count - collapseThreshold) more final games") {
        withAnimation { showAllFinals = true }
    }
}
```

### Pattern 7: Half-Sheet Calendar
**What:** Present a `.sheet()` with `.presentationDetents([.medium])` and `.presentationDragIndicator(.visible)`. Inside, render a month grid using `DatePicker` or a custom calendar built with `LazyVGrid`. Mark game dates with a dot indicator.
**When to use:** Calendar icon tap in navigation toolbar.
**Example:**
```swift
// Source: Apple presentationDetents docs, sarunw.com bottom sheet guide
.sheet(isPresented: $showCalendar) {
    CalendarSheetView(
        selectedDate: $viewModel.selectedDate,
        gameDates: viewModel.knownGameDates,
        onDateSelected: { date in
            viewModel.selectedDate = date
            showCalendar = false
        }
    )
    .presentationDetents([.medium])
    .presentationDragIndicator(.visible)
}
```

### Pattern 8: Logo Loading with Kingfisher
**What:** Use `KFImage(url)` from `import KingfisherSwiftUI`. Kingfisher maintains a disk + memory cache automatically. Show a placeholder while loading.
**When to use:** Every team logo in every game card.
**Example:**
```swift
// Source: onevcat/Kingfisher GitHub wiki — SwiftUI Support
import KingfisherSwiftUI

struct TeamLogoView: View {
    let logoURL: URL?

    var body: some View {
        if let url = logoURL {
            KFImage(url)
                .resizable()
                .placeholder { Image("logo-placeholder").resizable() }
                .scaledToFit()
                .frame(width: 52, height: 52)
        } else {
            Image("logo-placeholder")
                .resizable()
                .scaledToFit()
                .frame(width: 52, height: 52)
        }
    }
}
```

### Anti-Patterns to Avoid
- **Using `AsyncImage` for team logos:** Does not cache between view loads. Logos re-fetch on every scroll/navigate, causing flicker. Use Kingfisher's `KFImage`.
- **Calling URLSession directly in a View:** All network calls go through `APIClient`. Views call ViewModel methods, never URLSession.
- **Using `.refreshable` modifier alone:** Cannot replace the default spinner with a custom animation. Build offset-based detection instead.
- **Glass on game cards:** DESG-02 is locked. Game cards MUST use opaque backgrounds (`.background(Color("CardBackground"))` or `.background(.regularMaterial)`). Never apply `.glassEffect()` to content.
- **Pre-fetching all 60 days upfront:** Fetching ±30 days of game data at launch is expensive. Fetch only the dates index (or compute from API) and load per-day data on demand.
- **`ObservableObject` + `@Published`:** Causes full view re-renders. Use `@Observable` macro — iOS 26 target guarantees availability.
- **Date math without Eastern timezone:** The backend uses `America/New_York` for day boundaries. The iOS app must also use Eastern time when building date strings for the API, or games near midnight will appear on the wrong day.
- **Not adding `GlassKit` to the calendar sheet chrome:** The calendar bottom sheet is navigation chrome — if it uses glass for its header/toolbar, that glass must route through GlassKit per DESG-05.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Image caching | Custom `NSCache` + `URLSession` download manager | Kingfisher `KFImage` | Cache eviction, disk persistence, memory pressure handling, cancellation, progressive loading — all already solved |
| Blinking animation | Manual `Timer` + state updates | SwiftUI `repeatForever` animation with `withAnimation` | Timer-based blinking drifts; SwiftUI animation engine syncs to display refresh rate |
| Date formatting for API | Custom string manipulation | `DateFormatter` with `dateFormat = "yyyy-MM-dd"` and `timeZone = TimeZone(identifier: "America/New_York")` | Timezone edge cases are real — use the formatter the backend uses |
| Skeleton loading | Custom gray rectangle views | `.redacted(reason: .placeholder)` on real game card views | One modifier on a content view auto-generates a shape-matching placeholder |
| Calendar grid | Custom month layout engine | SwiftUI's `DatePicker` (inline style) or `LazyVGrid` with `Calendar` API | Month boundary math, week alignment, and locale handling are complex; use system calendar |
| Section sorting | Custom game status comparator | Simple enum mapping: live=0, scheduled=1, final=2, then sort by startTime | Swift's `sorted(by:)` with a comparator closure; no library needed |

**Key insight:** Networking, image caching, and date math have dozens of edge cases that production libraries already handle. Phase 3 should ship features, not infrastructure.

---

## Common Pitfalls

### Pitfall 1: AsyncImage Does Not Cache
**What goes wrong:** Team logos re-fetch from the network every time a game card scrolls off-screen and back into view. Users see repeated flicker and the network gets hammered.
**Why it happens:** Native `AsyncImage` intentionally does not persist an image cache between view loads. This is documented behavior, not a bug.
**How to avoid:** Use Kingfisher's `KFImage` instead. It provides both memory and disk cache automatically. Drop-in replacement syntax.
**Warning signs:** Logo images briefly show placeholder even after they were previously loaded; network activity spikes on scroll.

### Pitfall 2: Eastern Timezone Day Boundary Mismatch
**What goes wrong:** App fetches games for the wrong date near midnight Eastern. An 11 PM Eastern game shows up under the wrong day for users in Pacific time.
**Why it happens:** The backend's `dateBounds(for:)` uses `America/New_York` to compute day start/end. If the iOS app passes a date string computed in local time (e.g., `UTC-8`), the boundary differs.
**How to avoid:** When building the `yyyy-MM-dd` string for the API URL, always set `DateFormatter.timeZone = TimeZone(identifier: "America/New_York")`. Use the same calendar as the backend.
**Warning signs:** "No games today" shown when games exist; games appear under wrong date near midnight.

### Pitfall 3: Missing Available-Dates Index for Date Strip
**What goes wrong:** The date strip is supposed to only show dates with games. But the current API (`/api/v1/games/today` and `/api/v1/games/date/:date`) doesn't expose a list of dates that have games. To know which dates to show in the strip, the app either needs to fetch each day individually (expensive) or the backend needs to add an index endpoint.
**Why it happens:** The date strip design decision (only show game dates) wasn't reflected in the Phase 1 API design.
**How to avoid:** Add a lightweight backend endpoint: `GET /api/v1/games/dates?from=yyyy-MM-dd&to=yyyy-MM-dd` that returns an array of date strings with games. The iOS app calls this once on launch to populate the date strip. Alternative: the app fetches current month + adjacent months (3 requests) and derives the dates client-side. The backend endpoint is cleaner.
**Warning signs:** Date strip shows all calendar days (dead-end navigation to empty days), or requires 60 individual network calls to populate ±30 day window.

### Pitfall 4: Native .refreshable Blocks Custom Spinner
**What goes wrong:** Adding `.refreshable {}` to the ScrollView activates the system spinner, which cannot be replaced with the bouncing lacrosse ball animation.
**Why it happens:** `.refreshable` is tightly coupled to the system `UIRefreshControl` appearance. You can tint it, but cannot replace it with arbitrary SwiftUI content.
**How to avoid:** Do NOT use `.refreshable`. Instead, detect scroll offset using `PreferenceKey` + `GeometryReader` in a coordinate space named `"scroll"`. When offset exceeds the trigger threshold (~60pt), set `isRefreshing = true`, show the lacrosse ball animation at the top of the scroll view, and call `await viewModel.refresh()`.
**Warning signs:** Default iOS spinner appears during pull; lacrosse ball animation is unreachable.

### Pitfall 5: Swift 6.2 Concurrency and @Observable
**What goes wrong:** `@Observable` classes on iOS 26 (Swift 6.2) compile under strict concurrency checking. Unmarked mutable state accessed from multiple actors causes compile errors.
**Why it happens:** Swift 6.2's concurrency model is strict about data isolation. `@Observable` works best when the whole class is annotated `@MainActor`.
**How to avoid:** Annotate `ScoreboardViewModel` with both `@Observable` and `@MainActor`. Network calls use `async throws` and Swift 6.2's `NonisolatedNonsendingByDefault` feature — async functions run on the caller's actor by default, so calling `await apiClient.fetchGames(for:)` from a `@MainActor` VM stays on the main actor unless `apiClient` is explicitly `nonisolated`.
**Warning signs:** Sendability warnings, "Actor-isolated property cannot be mutated from a nonisolated context" errors during build.

### Pitfall 6: Glass on Card Content (DESG-02 Violation)
**What goes wrong:** Game cards accidentally get `.glassEffect()` applied, violating the locked design rule that content is opaque.
**Why it happens:** Easy to copy navigation glass patterns into content views.
**How to avoid:** The `GlassAuditTests.swift` test already checks that no `.glassEffect()` calls exist outside GlassKit. Run tests after every task. Card backgrounds should use explicit opaque colors: a named color from Assets (e.g., `Color("GameCard")`) or `.background(.regularMaterial)`.
**Warning signs:** `GlassAuditTests.noGlassEffectLeaks` test failure.

---

## Code Examples

### Full GameModel (Local Decodable Mirror of Backend DTO)
```swift
// Source: mirrors Sources/App/DTOs/GameResponse.swift and TeamBrief.swift
import Foundation

struct TeamModel: Decodable {
    let id: UUID
    let name: String
    let abbreviation: String
    let conference: String
    let logoAssetName: String?
    let record: String?
    let ranking: Int?
}

struct GameModel: Decodable, Identifiable {
    let id: UUID
    let homeTeam: TeamModel
    let awayTeam: TeamModel
    let homeScore: Int
    let awayScore: Int
    let status: String      // "scheduled", "live", "final"
    let period: String?
    let clock: String?
    let startTime: Date

    var gameStatus: GameStatus {
        switch status {
        case "live":      return .live
        case "final":     return .final
        default:          return .scheduled
        }
    }

    var isLive: Bool { status == "live" }
    var isFinal: Bool { status == "final" }
    var isScheduled: Bool { status == "scheduled" }
}

enum GameStatus: Int, Comparable {
    case live = 0
    case scheduled = 1
    case final = 2

    static func < (lhs: GameStatus, rhs: GameStatus) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
```

### API Key from Secure Config
```swift
// Source: Apple Info.plist access pattern — API key must NOT be hardcoded in source
// Store in Info.plist as a build setting variable:
// Info.plist: <key>APIBaseURL</key><string>$(API_BASE_URL)</string>
// Then in APIClient:
let baseURL = Bundle.main.object(forInfoDictionaryKey: "APIBaseURL") as? String ?? ""
let apiKey  = Bundle.main.object(forInfoDictionaryKey: "APIKey") as? String ?? ""
```

### Section Sorting
```swift
// Source: standard Swift sorted(by:) pattern
extension Array where Element == GameModel {
    func sortedByStatus() -> [GameModel] {
        sorted {
            if $0.gameStatus != $1.gameStatus {
                return $0.gameStatus < $1.gameStatus
            }
            return $0.startTime < $1.startTime
        }
    }
}
```

### Loading Skeleton with .redacted
```swift
// Source: Apple .redacted docs, avanderlee.com guide
struct ScoreboardView: View {
    @State private var viewModel = ScoreboardViewModel()

    var body: some View {
        Group {
            switch viewModel.state {
            case .loading:
                ForEach(0..<5, id: \.self) { _ in
                    GameCardView(game: .placeholder)
                        .redacted(reason: .placeholder)
                        .shimmering()  // optional shimmer modifier if added
                }
            case .loaded(let games):
                // real content
            case .empty:
                EmptyScoreboardView()
            case .error(let msg):
                ErrorView(message: msg) { await viewModel.refresh() }
            }
        }
    }
}
```

---

## Open Questions

1. **Available-dates index for the date strip**
   - What we know: The date strip must only show dates with games (CONTEXT.md locked decision). Current API has no endpoint returning a list of game dates for a range.
   - What's unclear: Whether to add a backend endpoint (`GET /api/v1/games/dates`) or fetch games for a rolling window and derive dates client-side.
   - Recommendation: Add a lightweight backend endpoint. A Swift `[String]` array of `yyyy-MM-dd` date strings is trivial to implement (one Fluent query selecting distinct `startTime` dates in a range). Client-side derivation requires 60+ requests or a single large-range fetch — both are worse.

2. **Logo URL vs. asset name strategy**
   - What we know: `TeamBrief.logoAssetName` is a `String?` field. Backend sets it when available. It could be a local asset name (for bundled logos) or a full URL string.
   - What's unclear: Whether logos will be bundled in the app at launch or fetched from a CDN/backend.
   - Recommendation: For Phase 3, treat `logoAssetName` as either a URL (try `URL(string:)`) or a local asset name fallback. Kingfisher handles URL logos; use `Image(logoAssetName)` for bundled assets. Document the convention in a code comment.

3. **API key storage in iOS client**
   - What we know: DATA-06 requires API key auth. The key must not be in the binary.
   - What's unclear: Where the key lives for development vs. production builds.
   - Recommendation: Store as an Xcode build setting (`$(API_KEY)`) injected via `.xcconfig` files (not committed). For CI/TestFlight, inject via environment variable in the Xcode Cloud / fastlane build. Read from `Info.plist` at runtime. Document this in the plan.

4. **Venue and broadcast info in API response**
   - What we know: CONTEXT.md says cards show "venue name and broadcast info when available." Current `GameResponse` DTO does not include venue or broadcast fields.
   - What's unclear: Whether to add these fields to the backend in Phase 3 or defer to a future phase.
   - Recommendation: If data is available from the NCAA API scraper, add `venue: String?` and `broadcast: String?` to `GameResponse` as part of Phase 3 backend work. If not available, omit from cards gracefully.

---

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Swift Testing (import Testing) — already used in `AppTabTests.swift` and `GlassAuditTests.swift` |
| Config file | Xcode project scheme (BarDownTests target in project.yml) |
| Quick run command | `xcodebuild test -project BarDown-iOS/BarDown.xcodeproj -scheme BarDown -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BarDownTests 2>&1 \| tail -30` |
| Full suite command | `xcodebuild test -project BarDown-iOS/BarDown.xcodeproj -scheme BarDown -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 \| tail -40` |
| Estimated runtime | ~20-40 seconds (logic tests; no UI tests) |

### Phase Requirements -> Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| SCOR-01 | Games decoded from API JSON into `GameModel` array | unit | `xcodebuild test ... -only-testing:BarDownTests/GameModelTests` | No — Wave 0 gap |
| SCOR-02 | `GameModel` exposes homeTeam, awayTeam with logo, score, status fields | unit | `xcodebuild test ... -only-testing:BarDownTests/GameModelTests` | No — Wave 0 gap |
| SCOR-03 | `TeamModel` exposes record and optional ranking | unit | `xcodebuild test ... -only-testing:BarDownTests/GameModelTests` | No — Wave 0 gap |
| SCOR-04 | Date strip only shows dates that have games | unit | `xcodebuild test ... -only-testing:BarDownTests/DateStripTests` | No — Wave 0 gap |
| SCOR-05 | Calendar sheet presented as half-sheet (medium detent) | manual (visual) | Build + launch on simulator | N/A — visual |
| SCOR-06 | Pull-to-refresh triggers `viewModel.refresh()` | unit | `xcodebuild test ... -only-testing:BarDownTests/ScoreboardViewModelTests` | No — Wave 0 gap |
| SCOR-07 | ViewModel transitions through loading/empty/error/loaded states | unit | `xcodebuild test ... -only-testing:BarDownTests/ScoreboardViewModelTests` | No — Wave 0 gap |
| TEAM-05 | No `.glassEffect()` on game cards (existing test covers this) | unit (code audit) | `xcodebuild test ... -only-testing:BarDownTests/GlassAuditTests` | YES — exists |

### Nyquist Sampling Rate
- **Minimum sample interval:** After every committed task — run: `xcodebuild build -project BarDown-iOS/BarDown.xcodeproj -scheme BarDown -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | tail -5`
- **Full suite trigger:** Before merging the final task of any plan wave
- **Phase-complete gate:** Full suite green before `/gsd:verify-work` runs
- **Estimated feedback latency per task:** ~20-40 seconds

### Wave 0 Gaps (must be created before implementation)
- [ ] `BarDown-iOS/BarDownTests/GameModelTests.swift` — covers SCOR-01, SCOR-02, SCOR-03: decode fixture JSON into `GameModel`, verify all required fields present
- [ ] `BarDown-iOS/BarDownTests/ScoreboardViewModelTests.swift` — covers SCOR-06, SCOR-07: test state machine transitions (loading → loaded, loading → empty, loading → error), test refresh
- [ ] `BarDown-iOS/BarDownTests/DateStripTests.swift` — covers SCOR-04: test that only dates with games appear, test date selection triggers correct fetch URL
- [ ] `BarDown-iOS/BarDownTests/Fixtures/games-response.json` — sample `[GameResponse]` JSON for decode tests (one live, one scheduled, one final game)

*(Existing `GlassAuditTests.swift` already covers TEAM-05 glass enforcement — no gap.)*

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `ObservableObject` + `@Published` + `@StateObject` | `@Observable` macro + `@State` | iOS 17 / Swift 5.9 (WWDC 2023) | Finer-grained view invalidation; simpler syntax; no Combine dependency |
| `onAppear { Task { await ... } }` | `.task(id:)` modifier | iOS 15 (WWDC 2021) | Auto-cancels on disappear; restarts on `id` change — correct pattern for date-driven reload |
| `AsyncImage` for remote images | Kingfisher `KFImage` / `CachedAsyncImage` | AsyncImage released iOS 15; no caching by design | `AsyncImage` is intentionally cache-less. For scrollable lists, caching is non-negotiable |
| `UIRefreshControl` / `.refreshable` spinner | Custom offset-detector + custom animation view | iOS 15 introduced `.refreshable`; custom still needed for branded spinners | Native spinner cannot be replaced with custom SwiftUI content |
| Half-screen sheets via `UISheetPresentationController` | `.sheet()` + `.presentationDetents([.medium])` | iOS 16 (WWDC 2022) | Pure SwiftUI; detents, drag indicator, background interaction all declarative |
| `ObservableObject` networking VMs | `@Observable` + `@MainActor` + Swift 6.2 approachable concurrency | Swift 6.2 / Xcode 26 (WWDC 2025) | `NonisolatedNonsendingByDefault` means async functions run on caller's actor by default — less annotation noise |

---

## Sources

### Primary (HIGH confidence)
- Apple Developer Docs: `ScrollViewReader` — programmatic scrolling API
- Apple Developer Docs: `presentationDetents(_:)` — half-sheet implementation
- Apple Developer Docs: `task(id:priority:_:)` — async data loading with re-fetch on id change
- Apple Developer Docs: Observation framework / `@Observable` macro — state management
- [onevcat/Kingfisher GitHub Wiki: SwiftUI Support](https://github.com/onevcat/Kingfisher/wiki/SwiftUI-Support) — `KFImage` API, caching behavior
- [avanderlee.com: Approachable Concurrency in Swift 6.2](https://www.avanderlee.com/concurrency/approachable-concurrency-in-swift-6-2-a-clear-guide/) — `@MainActor` + `NonisolatedNonsendingByDefault`

### Secondary (MEDIUM confidence)
- [matteomanferdini.com: AsyncImage in SwiftUI with Caching](https://matteomanferdini.com/swiftui-asyncimage/) — confirms AsyncImage does not cache; documents URLCache workarounds
- [Level Up Coding: Custom Pull-to-Refresh SwiftUI (Nov 2025)](https://medium.com/@kunal_yelne/building-a-beautiful-custom-pull-to-refresh-for-fitlane-swiftui-53ebdeccf8ae) — offset detection pattern
- [sarunw.com: Bottom Sheet with presentationDetents](https://sarunw.com/posts/swiftui-bottom-sheet/) — verified half-sheet pattern
- [hackingwithswift.com: ScrollViewReader](https://www.hackingwithswift.com/quick-start/swiftui/how-to-make-a-scroll-view-move-to-a-location-using-scrollviewreader) — scrollTo pattern for date strip
- [avanderlee.com: Downloading and Caching images in SwiftUI](https://www.avanderlee.com/swiftui/downloading-caching-images/) — image caching approaches
- [avanderlee.com: MainActor dispatch](https://www.avanderlee.com/swift/mainactor-dispatch-main-thread/) — MainActor for ViewModel pattern

### Tertiary (LOW confidence — needs implementation validation)
- Custom pull-to-refresh via `PreferenceKey` + coordinate space: Pattern derived from multiple community sources; exact compatibility with iOS 26's scroll behavior should be verified during implementation
- `logoAssetName` field as URL vs. local asset: Convention not yet locked; needs team decision during Wave 0

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — All APIs are native iOS 26 SDK or well-established SPM packages with verified documentation
- Architecture: HIGH — Patterns follow Phase 2 conventions; `@Observable`, `.task(id:)`, `presentationDetents` are all well-documented
- Pitfalls: HIGH — AsyncImage caching gap is documented behavior; timezone issue mirrors Phase 1 pattern; custom pull-to-refresh limitation is confirmed
- Open questions: MEDIUM — Available-dates API gap is a real planning blocker; logo URL strategy needs team decision

**Research date:** 2026-02-25
**Valid until:** 2026-03-25 (stable iOS 26 SDK; Kingfisher 8.x is active development but API is stable)
