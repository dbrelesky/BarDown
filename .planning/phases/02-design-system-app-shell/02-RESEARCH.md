# Phase 2: Design System & App Shell - Research

**Researched:** 2026-02-25
**Domain:** SwiftUI iOS 26 Liquid Glass, GlassKit design system, universal app shell
**Confidence:** HIGH

## Summary

Phase 2 introduces the iOS client as a new Xcode project within the existing monorepo. The core work is threefold: (1) create an Xcode 26 project targeting iOS 26+ with SwiftUI App lifecycle for universal iPhone/iPad, (2) build a `GlassKit` Swift module that centralizes all Liquid Glass decisions so feature screens never call `.glassEffect()` directly, and (3) wire up tab-based navigation using the system `TabView` which automatically receives Liquid Glass treatment in iOS 26.

The existing repository contains the Vapor 4 backend (Package.swift at root, Sources/App/). The iOS Xcode project should live in a separate directory (e.g., `BarDown-iOS/` or `iOS/`) to avoid conflicts with the SPM-based backend. Shared model types (DTOs) can be extracted to a local Swift package later but are NOT required for this phase -- the iOS app will define its own model layer initially.

**Primary recommendation:** Use the standard SwiftUI `TabView` with the new `Tab` API for navigation (system handles glass automatically), build a `GlassKit` module as a local Swift package containing reusable view modifiers and design tokens, and set `.preferredColorScheme(.dark)` as the default with automatic light mode support via system override.

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| DESG-01 | App uses Apple Liquid Glass design language for all navigation chrome (tab bar, toolbar, sheets) | System TabView, toolbar, and sheets automatically receive Liquid Glass in iOS 26. No manual `.glassEffect()` needed for standard navigation chrome. GlassKit wraps any custom glass usage. |
| DESG-02 | Content layer (game cards, stats, logos) is opaque and vivid -- no glass on content | GlassKit enforces the rule: glass modifiers exist only for navigation-layer components. Content views never import or use glass APIs. Enforced by code review / module boundary. |
| DESG-03 | Dark mode is the hero aesthetic; light mode supported automatically via OS preference | `.preferredColorScheme(.dark)` on root view sets dark as default. Removing the modifier (or passing `nil`) falls back to OS preference. Liquid Glass adapts automatically to both schemes. |
| DESG-04 | App runs as universal iPhone + iPad app | Xcode project created with "iPhone + iPad" device family. SwiftUI layouts adapt automatically. No iPad-specific split view needed for v1 (deferred to ENHN-04). |
| DESG-05 | GlassKit design system module centralizes all glass decisions for consistency | Local Swift package `GlassKit` contains all `.glassEffect()` calls, design tokens, and reusable view modifiers. Feature code imports GlassKit, never calls glass APIs directly. |
</phase_requirements>

## Standard Stack

### Core
| Library/API | Version | Purpose | Why Standard |
|-------------|---------|---------|--------------|
| SwiftUI | iOS 26+ | UI framework | First-class Liquid Glass support; Apple's primary UI framework |
| Xcode 26 | 26.x | IDE and build system | Required for iOS 26 SDK, Liquid Glass APIs, and provisioning |
| Swift 6.x | 6.2+ | Language | Ships with Xcode 26; required for iOS 26 targets |

### Supporting
| Library/API | Version | Purpose | When to Use |
|-------------|---------|---------|-------------|
| `.glassEffect()` modifier | iOS 26+ | Liquid Glass on custom views | Only inside GlassKit module for custom navigation elements |
| `GlassEffectContainer` | iOS 26+ | Groups multiple glass elements | When multiple glass buttons/controls need proximity morphing |
| `.glassEffectID(_:in:)` | iOS 26+ | Morphing transitions between glass elements | Expandable menus, tab transitions |
| `TabView` + `Tab` API | iOS 26+ | Tab-based navigation | Primary app navigation; system applies glass automatically |
| `.tabBarMinimizeBehavior()` | iOS 26+ | Tab bar collapse on scroll | Scoreboard and list screens for more content space |
| `.tabViewBottomAccessory()` | iOS 26+ | Content above tab bar | Optional: mini-player or quick actions in future phases |
| `.buttonStyle(.glass)` | iOS 26+ | Secondary glass buttons | Navigation-layer buttons only |
| `.buttonStyle(.glassProminent)` | iOS 26+ | Primary glass buttons | Primary floating action buttons |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Local Swift package for GlassKit | Folder-based module in same target | Package provides true module boundary and import enforcement; folder is simpler but can't prevent direct `.glassEffect()` calls in feature code |
| New `Tab` API | Deprecated `tabItem(_:)` | `tabItem` is deprecated in iOS 26; new `Tab` struct is the supported path |
| `.preferredColorScheme(.dark)` | `Info.plist UIUserInterfaceStyle = Dark` | SwiftUI modifier is more flexible; can be removed to follow system. Info.plist is a hard lock. |

**Installation:**
No third-party packages required for this phase. All APIs are native iOS 26 SDK.

## Architecture Patterns

### Recommended Project Structure
```
BarDown/                           # Existing repo root
├── Sources/App/                   # Existing Vapor backend
├── Package.swift                  # Existing backend SPM manifest
├── BarDown-iOS/                   # NEW: Xcode project directory
│   ├── BarDown.xcodeproj
│   ├── BarDown/
│   │   ├── BarDownApp.swift       # @main App entry, TabView, dark mode
│   │   ├── ContentView.swift      # Root view with tab structure
│   │   ├── Assets.xcassets/       # Colors, images, app icon
│   │   ├── Tabs/                  # Tab destination views (placeholder)
│   │   │   ├── ScoreboardTab.swift
│   │   │   ├── TeamsTab.swift
│   │   │   ├── RankingsTab.swift
│   │   │   └── SettingsTab.swift
│   │   └── Preview Content/
│   └── Packages/
│       └── GlassKit/              # Local Swift package
│           ├── Package.swift
│           └── Sources/GlassKit/
│               ├── GlassKit.swift          # Namespace and tokens
│               ├── GlassModifiers.swift    # ViewModifier implementations
│               └── GlassComponents.swift   # Reusable glass views
└── Tests/                         # Existing backend tests
```

### Pattern 1: GlassKit Design System Module
**What:** A local Swift package that owns all Liquid Glass API calls. Feature code imports `GlassKit` and uses semantic modifiers like `.glassNavigation()` or `.glassFloatingAction()` instead of raw `.glassEffect()`.
**When to use:** Always -- every glass effect in the app goes through GlassKit.
**Example:**
```swift
// Source: Level Up Coding GlassKit guide + Apple docs
// GlassKit/Sources/GlassKit/GlassModifiers.swift

import SwiftUI

// MARK: - Design Tokens
public enum GlassToken {
    /// Standard navigation chrome glass (tab bar, toolbar, nav bar)
    public static let navigation = Glass.regular
    /// Interactive floating controls (FABs, action buttons)
    public static let action = Glass.regular.interactive()
    /// Subtle overlay on media-heavy backgrounds
    public static let subtle = Glass.clear
    /// Semantic tinted glass for primary actions
    public static func tinted(_ color: Color) -> Glass {
        Glass.regular.tint(color).interactive()
    }
}

// MARK: - View Modifiers
public struct GlassNavigationModifier: ViewModifier {
    public func body(content: Content) -> some View {
        content.glassEffect(GlassToken.navigation)
    }
}

public struct GlassFloatingActionModifier: ViewModifier {
    let tint: Color?

    public func body(content: Content) -> some View {
        if let tint {
            content.glassEffect(GlassToken.tinted(tint))
        } else {
            content.glassEffect(GlassToken.action)
        }
    }
}

// MARK: - View Extensions
public extension View {
    func glassNavigation() -> some View {
        modifier(GlassNavigationModifier())
    }

    func glassFloatingAction(tint: Color? = nil) -> some View {
        modifier(GlassFloatingActionModifier(tint: tint))
    }
}
```

### Pattern 2: Tab-Based Navigation with System Glass
**What:** Standard `TabView` with the new `Tab` API. The system automatically applies Liquid Glass to the tab bar -- no manual glass calls needed.
**When to use:** App root navigation.
**Example:**
```swift
// Source: Donny Wals iOS 26 tab bar guide + Apple docs
// BarDown/ContentView.swift

import SwiftUI

enum AppTab: String, CaseIterable {
    case scoreboard, teams, rankings, settings

    var title: String {
        switch self {
        case .scoreboard: return "Scores"
        case .teams: return "Teams"
        case .rankings: return "Rankings"
        case .settings: return "Settings"
        }
    }

    var icon: String {
        switch self {
        case .scoreboard: return "sportscourt.fill"
        case .teams: return "heart.fill"
        case .rankings: return "chart.bar.fill"
        case .settings: return "gearshape.fill"
        }
    }
}

struct ContentView: View {
    @State private var selectedTab: AppTab = .scoreboard

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab(AppTab.scoreboard.title, systemImage: AppTab.scoreboard.icon, value: .scoreboard) {
                ScoreboardTab()
            }
            Tab(AppTab.teams.title, systemImage: AppTab.teams.icon, value: .teams) {
                TeamsTab()
            }
            Tab(AppTab.rankings.title, systemImage: AppTab.rankings.icon, value: .rankings) {
                RankingsTab()
            }
            Tab(AppTab.settings.title, systemImage: AppTab.settings.icon, value: .settings) {
                SettingsTab()
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
    }
}
```

### Pattern 3: Dark Mode Default with System Override
**What:** Set dark mode as the hero aesthetic at the app root. Light mode activates automatically when the user changes OS appearance.
**When to use:** App entry point.
**Example:**
```swift
// BarDown/BarDownApp.swift

import SwiftUI

@main
struct BarDownApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark) // Dark is hero mode
        }
    }
}
```
**Note:** `.preferredColorScheme(.dark)` locks to dark regardless of system setting. For "dark default but respect OS override," the app can read a user preference and pass `nil` to follow the system. For v1, locking to dark satisfies DESG-03's "dark mode is the hero aesthetic." Light mode support means the color assets and GlassKit tokens must produce coherent results in both schemes -- Liquid Glass adapts automatically.

### Anti-Patterns to Avoid
- **Glass on content:** Never apply `.glassEffect()` to game cards, list rows, stat tables, or any scrollable content. Content must be opaque and vivid.
- **Glass on glass stacking:** Never layer glass elements without `GlassEffectContainer`. Glass cannot sample other glass.
- **Mixing glass variants:** Never combine `.regular` and `.clear` in the same `GlassEffectContainer`.
- **Raw `.glassEffect()` in feature code:** All glass calls must go through GlassKit. Direct calls bypass the design system.
- **Deprecated `tabItem(_:)` API:** Use the new `Tab` struct inside `TabView`. The old `tabItem` modifier is deprecated in iOS 26.
- **Custom navigation bar glass:** Let the system handle it. `NavigationStack` toolbars get glass automatically.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Tab bar glass effect | Custom glass tab bar | `TabView` with `Tab` API | System handles Liquid Glass, minimize behavior, and accessibility automatically |
| Toolbar glass | Custom toolbar with `.glassEffect()` | `.toolbar { }` modifier | System applies glass to toolbar items automatically |
| Sheet glass background | Custom sheet with glass overlay | `.sheet()` with `.presentationDetents()` | System applies inset glass to sheets automatically |
| Dark/light mode theming | Custom theme engine | `.preferredColorScheme()` + Asset Catalog named colors | System handles Liquid Glass adaptation across schemes |
| Accessibility for glass | Manual Reduce Transparency handling | Native glass APIs | System automatically adjusts for Reduce Transparency, Increase Contrast, Reduce Motion |
| Button glass styles | Custom glass button component | `.buttonStyle(.glass)` / `.buttonStyle(.glassProminent)` | System styles handle press states, shimmer, illumination |

**Key insight:** iOS 26 Liquid Glass is designed to be automatic for standard navigation chrome. The system handles tab bars, toolbars, sheets, navigation bars, menus, popovers, and alerts. You only need `.glassEffect()` for CUSTOM floating controls that aren't covered by system components.

## Common Pitfalls

### Pitfall 1: Applying Glass to Content
**What goes wrong:** Game cards, stat rows, or list items get `.glassEffect()` applied, creating a blurry, unreadable "blur pile."
**Why it happens:** Desire to make the app look "glassy" everywhere.
**How to avoid:** GlassKit module boundary. Feature code imports `GlassKit` but only uses it for navigation-layer elements. Content views use opaque backgrounds with named colors from the asset catalog.
**Warning signs:** `.glassEffect()` appearing in any file outside `GlassKit/Sources/`.

### Pitfall 2: Stacking Glass on Glass
**What goes wrong:** Tab bar glass overlaps with a custom glass toolbar, creating visual artifacts. Glass cannot properly sample other glass.
**Why it happens:** Adding custom glass elements near system-provided glass (e.g., a glass FAB near the glass tab bar).
**How to avoid:** Use `GlassEffectContainer` to group glass elements that are near each other. Let the system handle standard chrome.
**Warning signs:** Visual muddiness or contrast loss in areas where multiple glass surfaces overlap.

### Pitfall 3: Forgetting Xcode Project Separation
**What goes wrong:** Adding an iOS target to the existing `Package.swift` creates build conflicts between Vapor (server) dependencies and iOS SDK.
**Why it happens:** Monorepo temptation to share everything.
**How to avoid:** Create a separate Xcode project (`BarDown-iOS/BarDown.xcodeproj`) for the iOS app. The backend `Package.swift` stays server-only. Shared code can be extracted to a local package later.
**Warning signs:** Build errors mentioning NIO, Vapor, or Linux-only APIs in the iOS target.

### Pitfall 4: Using tabItem Instead of Tab
**What goes wrong:** `tabItem(_:)` is deprecated in iOS 26. It may compile with warnings but misses new features like minimize behavior and search tab integration.
**Why it happens:** Copying older SwiftUI tab examples.
**How to avoid:** Use the `Tab` struct: `Tab("Title", systemImage: "icon", value: .tab) { Content() }`.
**Warning signs:** Deprecation warnings in Xcode 26.

### Pitfall 5: Hard-Locking Dark Mode via Info.plist
**What goes wrong:** Setting `UIUserInterfaceStyle = Dark` in Info.plist prevents light mode entirely, even when the user expects it from OS settings.
**Why it happens:** Wanting to enforce dark mode.
**How to avoid:** Use `.preferredColorScheme(.dark)` in SwiftUI which can be overridden programmatically. For v1, this is acceptable since "dark is hero" but light must still be "coherent" per DESG-03.
**Warning signs:** App ignores OS Appearance toggle in Settings.

### Pitfall 6: Over-Engineering GlassKit
**What goes wrong:** GlassKit becomes a massive framework with dozens of components before any feature screen exists.
**Why it happens:** Design system enthusiasm.
**How to avoid:** Start with tokens (3 glass variants) and 2-3 view modifiers. Add components as feature screens need them. The module boundary is the important part, not the component count.
**Warning signs:** GlassKit has more lines of code than the feature screens combined.

## Code Examples

### App Entry Point with Dark Mode
```swift
// Source: Apple SwiftUI docs + DESG-03 requirement
import SwiftUI

@main
struct BarDownApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
    }
}
```

### GlassKit Local Package Manifest
```swift
// Source: SPM documentation
// BarDown-iOS/Packages/GlassKit/Package.swift

// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "GlassKit",
    platforms: [.iOS(.v26)],
    products: [
        .library(name: "GlassKit", targets: ["GlassKit"]),
    ],
    targets: [
        .target(name: "GlassKit"),
        .testTarget(name: "GlassKitTests", dependencies: ["GlassKit"]),
    ]
)
```

### GlassEffectContainer for Grouped Controls
```swift
// Source: Apple docs + DEV Community best practices
import SwiftUI
import GlassKit

struct FloatingControls: View {
    @Namespace private var namespace
    @State private var isExpanded = false

    var body: some View {
        GlassEffectContainer(spacing: 20) {
            if isExpanded {
                Button("Filter") { }
                    .glassFloatingAction()
                    .glassEffectID("filter", in: namespace)

                Button("Calendar") { }
                    .glassFloatingAction()
                    .glassEffectID("calendar", in: namespace)
            }

            Button {
                withAnimation(.bouncy) { isExpanded.toggle() }
            } label: {
                Image(systemName: isExpanded ? "xmark" : "plus")
                    .frame(width: 44, height: 44)
            }
            .glassFloatingAction(tint: .blue)
            .glassEffectID("toggle", in: namespace)
        }
    }
}
```

### Placeholder Tab Content (Opaque, No Glass)
```swift
// Source: Apple design philosophy - content is opaque
struct ScoreboardTab: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    // Placeholder for Phase 3 game cards
                    ForEach(0..<5) { _ in
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.regularMaterial) // NOT glass -- opaque material
                            .frame(height: 100)
                            .overlay {
                                Text("Game Card Placeholder")
                                    .foregroundStyle(.secondary)
                            }
                    }
                }
                .padding()
            }
            .navigationTitle("Scores")
        }
    }
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `tabItem(_:)` modifier | `Tab` struct in `TabView` | iOS 26 (WWDC 2025) | Deprecated; new API supports minimize, search tab, bottom accessory |
| `.material(.ultraThinMaterial)` blur | `.glassEffect(.regular)` | iOS 26 (WWDC 2025) | Liquid Glass replaces Material for navigation chrome |
| Manual dark/light theming | Liquid Glass auto-adapts | iOS 26 (WWDC 2025) | Glass automatically adjusts to color scheme |
| Custom glass/blur components | Native `.glassEffect()` API | iOS 26 (WWDC 2025) | First-party API with accessibility, motion, and performance built in |
| `NavigationView` | `NavigationStack` | iOS 16+ | `NavigationView` deprecated; Stack is the standard |

**Deprecated/outdated:**
- `tabItem(_:)`: Deprecated in iOS 26. Use `Tab` struct.
- `.material()` / `.ultraThinMaterial`: Still works but Liquid Glass is the new standard for navigation chrome.
- `NavigationView`: Deprecated since iOS 16. Use `NavigationStack`.

## Open Questions

1. **Shared DTO package between backend and iOS app**
   - What we know: Phase 1 backend has DTOs in `Sources/App/DTOs/`. The iOS app will need matching model types.
   - What's unclear: Whether to extract shared types now or duplicate and sync later.
   - Recommendation: Duplicate for now. Phase 2 scope is the shell, not networking. Extract a shared package when Phase 3 wires up API calls. This avoids premature coupling.

2. **Tab icons for lacrosse context**
   - What we know: SF Symbols has sports icons (`sportscourt.fill`, `figure.run`) but no lacrosse-specific icons.
   - What's unclear: Whether custom tab icons are needed or if generic sports icons suffice.
   - Recommendation: Use SF Symbols for now (`sportscourt.fill` for Scores, `heart.fill` for Teams, `chart.bar.fill` for Rankings, `gearshape.fill` for Settings). Custom icons can replace them later.

3. **iPad layout for v1**
   - What we know: DESG-04 requires universal app. ENHN-04 (iPad-optimized split-view) is deferred to v2.
   - What's unclear: Whether the iPad should get any layout adaptations or just scale up the iPhone layout.
   - Recommendation: Run the iPhone layout on iPad for v1. SwiftUI's TabView works on both. No sidebar or split view needed until v2.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | XCTest (Xcode built-in) |
| Config file | Xcode project scheme (auto-configured) |
| Quick run command | `xcodebuild test -project BarDown-iOS/BarDown.xcodeproj -scheme BarDown -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BarDownTests 2>&1 \| tail -20` |
| Full suite command | `xcodebuild test -project BarDown-iOS/BarDown.xcodeproj -scheme BarDown -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 \| tail -40` |
| Estimated runtime | ~15-30 seconds (shell app, minimal views) |

### Phase Requirements -> Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| DESG-01 | Tab bar uses Liquid Glass (system automatic) | smoke / manual | Build + launch on iOS 26 simulator | No -- Wave 0 gap |
| DESG-02 | Content areas have no glass effect | unit (code audit) | Grep for `.glassEffect` outside GlassKit | No -- Wave 0 gap |
| DESG-03 | Dark mode default, light mode coherent | unit | Test `preferredColorScheme` is `.dark` on root view | No -- Wave 0 gap |
| DESG-04 | Universal iPhone + iPad | smoke | Build for both simulator destinations | No -- Wave 0 gap |
| DESG-05 | GlassKit module exists and centralizes glass | unit (structural) | Verify GlassKit package compiles, verify no `.glassEffect` outside it | No -- Wave 0 gap |

### Nyquist Sampling Rate
- **Minimum sample interval:** After every committed task -> run: `xcodebuild build -project BarDown-iOS/BarDown.xcodeproj -scheme BarDown -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | tail -5` (build check)
- **Full suite trigger:** Before merging final task of any plan wave
- **Phase-complete gate:** Full suite green before `/gsd:verify-work` runs
- **Estimated feedback latency per task:** ~15-30 seconds

### Wave 0 Gaps (must be created before implementation)
- [ ] `BarDown-iOS/BarDownTests/GlassKitTests.swift` -- covers DESG-05 (GlassKit module compiles, tokens exist)
- [ ] `BarDown-iOS/BarDownTests/AppStructureTests.swift` -- covers DESG-01, DESG-04 (app builds, tab view exists)
- [ ] `BarDown-iOS/BarDownTests/DesignAuditTests.swift` -- covers DESG-02 (grep-based: no `.glassEffect` outside GlassKit)
- [ ] Shell script: `scripts/audit-glass-usage.sh` -- covers DESG-02, DESG-05 (find `.glassEffect` calls outside GlassKit module)

**Note:** DESG-01 (Liquid Glass on navigation chrome) and DESG-03 (dark/light mode visual coherence) are primarily visual and require manual verification on simulator/device. Automated tests can verify structural correctness (right modifiers applied, right scheme set) but not visual rendering.

## Sources

### Primary (HIGH confidence)
- [Apple: glassEffect(_:in:) documentation](https://developer.apple.com/documentation/swiftui/view/glasseffect(_:in:)) -- API signatures, parameters, variants
- [Apple: Applying Liquid Glass to custom views](https://developer.apple.com/documentation/SwiftUI/Applying-Liquid-Glass-to-custom-views) -- Official design guidelines
- [LiquidGlassReference (GitHub)](https://github.com/conorluddy/LiquidGlassReference) -- Comprehensive API reference with all code patterns
- [Donny Wals: Exploring tab bars on iOS 26](https://www.donnywals.com/exploring-tab-bars-on-ios-26-with-liquid-glass/) -- Tab API, minimize behavior, bottom accessory, search tab

### Secondary (MEDIUM confidence)
- [DEV Community: Liquid Glass Best Practices](https://dev.to/diskcleankit/liquid-glass-in-swift-official-best-practices-for-ios-26-macos-tahoe-1coo) -- Anti-patterns, button styles, accessibility, verified against Apple docs
- [Level Up Coding: Build a Liquid Glass Design System](https://levelup.gitconnected.com/build-a-liquid-glass-design-system-in-swiftui-ios-26-bfa62bcba5be) -- GlassKit module pattern, tokens, reusable modifiers
- [Donny Wals: Designing custom UI with Liquid Glass](https://www.donnywals.com/designing-custom-ui-with-liquid-glass-on-ios-26/) -- Custom component patterns, GlassEffectContainer
- [Swift with Majid: Glassifying tabs in SwiftUI](https://swiftwithmajid.com/2025/06/24/glassifying-tabs-in-swiftui/) -- Tab customization patterns

### Tertiary (LOW confidence)
- Monorepo structure (backend + iOS in same repo) -- based on community patterns, not official Apple guidance. Needs validation during implementation.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- All APIs are native iOS 26 SDK, documented by Apple, verified against multiple sources
- Architecture: HIGH -- GlassKit module pattern is recommended by Apple's design guidelines and multiple community guides
- Pitfalls: HIGH -- Anti-patterns are well-documented across Apple docs and community sources
- Project structure: MEDIUM -- Monorepo layout with separate Xcode project is standard practice but specific directory structure is a recommendation

**Research date:** 2026-02-25
**Valid until:** 2026-03-25 (stable -- iOS 26 APIs are shipped and documented)
