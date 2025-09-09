import MEGADesignToken
import SwiftUI

public struct BackgroundModifier: ViewModifier {
    public func body(content: Content) -> some View {
        background(content: content)
    }
    
    @ViewBuilder
    func background(content: Content) -> some View {
        content
            .scrollContentBackground(.hidden)
            .background(TokenColors.Background.page.swiftUI)
    }
}

public extension View {
    @ViewBuilder
    func background() -> some View {
        modifier(
            BackgroundModifier()
        )
    }
}
