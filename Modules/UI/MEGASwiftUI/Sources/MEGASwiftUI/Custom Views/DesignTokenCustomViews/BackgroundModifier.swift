import MEGADesignToken
import SwiftUI

public struct BackgroundModifier: ViewModifier {
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
            if #available(iOS 16.0, *) {
                content
                    .scrollContentBackground(.hidden)
                    .background(TokenColors.Background.page.swiftUI)
            } else {
                content
                    .background(TokenColors.Background.page.swiftUI)
            }
        } else {
            content
        }
    }
}

public extension View {
    @ViewBuilder
    func designTokenBackground(_ isDesignTokenEnabled: Bool) -> some View {
        modifier(BackgroundModifier(isDesignTokenEnabled: isDesignTokenEnabled))
    }
}
