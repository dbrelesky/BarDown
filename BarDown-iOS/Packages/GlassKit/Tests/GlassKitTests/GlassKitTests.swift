import Testing
import SwiftUI
@testable import GlassKit

// MARK: - GlassToken Tests

@Suite("GlassToken Design Tokens")
struct GlassTokenTests {

    @Test("Navigation token uses Glass.regular")
    func navigationToken() {
        let token = GlassToken.navigation
        #expect(token == Glass.regular)
    }

    @Test("Action token is interactive")
    func actionToken() {
        let token = GlassToken.action
        #expect(token == Glass.regular.interactive())
    }

    @Test("Subtle token uses Glass.clear")
    func subtleToken() {
        let token = GlassToken.subtle
        #expect(token == Glass.clear)
    }

    @Test("Tinted token accepts a color and returns interactive glass")
    func tintedToken() {
        let token = GlassToken.tinted(.blue)
        #expect(token == Glass.regular.tint(.blue).interactive())
    }
}

// MARK: - View Modifier Tests

@Suite("Glass View Modifiers")
struct GlassModifierTests {

    @Test("GlassNavigationModifier can be instantiated")
    func navigationModifierExists() {
        let modifier = GlassNavigationModifier()
        #expect(modifier is GlassNavigationModifier)
    }

    @Test("GlassFloatingActionModifier without tint")
    func floatingActionNoTint() {
        let modifier = GlassFloatingActionModifier(tint: nil)
        #expect(modifier.tint == nil)
    }

    @Test("GlassFloatingActionModifier with tint")
    func floatingActionWithTint() {
        let modifier = GlassFloatingActionModifier(tint: .red)
        #expect(modifier.tint == .red)
    }

    @Test("glassNavigation() extension compiles on View")
    func navigationExtension() {
        let view = Color.clear.glassNavigation()
        #expect(view != nil)
    }

    @Test("glassFloatingAction() extension compiles on View")
    func floatingActionExtension() {
        let view = Color.clear.glassFloatingAction()
        #expect(view != nil)
    }

    @Test("glassFloatingAction(tint:) extension accepts color")
    func floatingActionTintExtension() {
        let view = Color.clear.glassFloatingAction(tint: .green)
        #expect(view != nil)
    }
}
