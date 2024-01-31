import MEGADesignToken
import SwiftUI

public struct SeparatorModifier: ViewModifier {
    private let isDesignTokenEnabled: Bool
    
    public init(isDesignTokenEnabled: Bool) {
        self.isDesignTokenEnabled = isDesignTokenEnabled
    }
    
    public func body(content: Content) -> some View {
        separator(with: content)
    }
    
    @ViewBuilder
    func separator(with content: Content) -> some View {
        if isDesignTokenEnabled {
            content
                .listRowSeparatorTint(TokenColors.Border.strong.swiftUI)
        } else {
            content
        }
    }
}

public extension View {
    @ViewBuilder
    func designTokenSeparator(_ isDesignTokenEnabled: Bool) -> some View {
        modifier(SeparatorModifier(isDesignTokenEnabled: isDesignTokenEnabled))
    }
}
