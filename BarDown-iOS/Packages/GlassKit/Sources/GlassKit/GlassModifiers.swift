import SwiftUI

// MARK: - Design Tokens
public enum GlassToken {
    /// Standard navigation chrome glass (used by custom nav elements)
    public static let navigation = Glass.regular
    /// Interactive floating controls (FABs, action buttons)
    public static let action = Glass.regular.interactive()
    /// Subtle overlay for media-heavy backgrounds
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
