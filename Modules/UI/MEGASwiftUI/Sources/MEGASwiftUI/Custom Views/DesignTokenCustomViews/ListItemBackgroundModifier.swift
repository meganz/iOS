import MEGADesignToken
import SwiftUI

public struct ListItemBackgroundModifier: ViewModifier {
    private let isDesignTokenEnabled: Bool

    public init(isDesignTokenEnabled: Bool) {
        self.isDesignTokenEnabled = isDesignTokenEnabled
    }

    public func body(content: Content) -> some View {
        background(content: content)
    }

    @ViewBuilder
    func background(content: Content) -> some View {
        if isDesignTokenEnabled {
            content
                .listRowBackground(TokenColors.Background.page.swiftUI)
        } else {
            content
        }
    }
}

public extension View {
    @ViewBuilder
    func designTokenListItemBackground(_ isDesignTokenEnabled: Bool) -> some View {
        modifier(ListItemBackgroundModifier(isDesignTokenEnabled: isDesignTokenEnabled))
    }
}
