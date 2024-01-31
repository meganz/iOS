import MEGADesignToken
import SwiftUI

public struct ToggleModifier: ViewModifier {
    private let isDesignTokenEnabled: Bool
    
    public init(isDesignTokenEnabled: Bool) {
        self.isDesignTokenEnabled = isDesignTokenEnabled
    }
    
    public func body(content: Content) -> some View {
        toggle(with: content)
    }
    
    @ViewBuilder
    func toggle(with content: Content) -> some View {
        if isDesignTokenEnabled {
            content.tint(TokenColors.Support.success.swiftUI)
        } else {
            content
        }
    }
}

public extension View {
    @ViewBuilder
    func designTokenToggleBackground(_ isDesignTokenEnabled: Bool) -> some View {
        modifier(ToggleModifier(isDesignTokenEnabled: isDesignTokenEnabled))
    }
}
