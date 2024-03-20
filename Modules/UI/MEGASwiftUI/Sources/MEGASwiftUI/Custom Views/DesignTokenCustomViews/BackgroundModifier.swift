import MEGADesignToken
import SwiftUI

public struct BackgroundModifier: ViewModifier {
    private let isDesignTokenEnabled: Bool
    private let legacyColor: Color?
    
    public init(isDesignTokenEnabled: Bool, legacyColor: Color? = nil) {
        self.isDesignTokenEnabled = isDesignTokenEnabled
        self.legacyColor = legacyColor
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
            if let legacyColor {
                if #available(iOS 16.0, *) {
                    content
                        .scrollContentBackground(.hidden)
                        .background(legacyColor)
                } else {
                    content
                        .background(legacyColor)
                }
            } else {
                content
            }
        }
    }
}

public extension View {
    @ViewBuilder
    func designTokenBackground(_ isDesignTokenEnabled: Bool, legacyColor: Color? = nil) -> some View {
        modifier(
            BackgroundModifier(
                isDesignTokenEnabled: isDesignTokenEnabled,
                legacyColor: legacyColor
            )
        )
    }
}
