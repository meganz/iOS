import MEGADesignToken
import SwiftUI

public struct ToggleModifier: ViewModifier {
    public func body(content: Content) -> some View {
        toggle(with: content)
    }
    
    @ViewBuilder
    func toggle(with content: Content) -> some View {
        content.tint(TokenColors.Support.success.swiftUI)
    }
}

public extension View {
    @ViewBuilder
    func toggleBackground() -> some View {
        modifier(ToggleModifier())
    }
}
