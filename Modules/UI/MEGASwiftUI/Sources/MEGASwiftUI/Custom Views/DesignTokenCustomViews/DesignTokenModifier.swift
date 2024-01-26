import MEGADesignToken
import SwiftUI

public struct ToggleModifier: ViewModifier {
    private let isDesignTokenEnabled: Bool
    
    public init(isDesignTokenEnabled: Bool) {
        self.isDesignTokenEnabled = isDesignTokenEnabled
    }
    
    public func body(content: Content) -> some View {
        designTokenSupportView(content: content)
    }
    
    @ViewBuilder
    func designTokenSupportView(content: Content) -> some View {
        if isDesignTokenEnabled {
            content.tint(TokenColors.Support.success.swiftUI)
        } else {
            content
        }
    }
}
