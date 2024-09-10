import MEGADesignToken
import SwiftUI

public struct SeparatorModifier: ViewModifier {
    public func body(content: Content) -> some View {
        separator(with: content)
    }
    
    @ViewBuilder
    func separator(with content: Content) -> some View {
        content
            .listRowSeparatorTint(TokenColors.Border.strong.swiftUI)
    }
}

public extension View {
    @ViewBuilder
    func separator() -> some View {
        modifier(SeparatorModifier())
    }
}
