import MEGADesignToken
import SwiftUI

public struct BackgroundModifier: ViewModifier {
    public func body(content: Content) -> some View {
        background(content: content)
    }
    
    @ViewBuilder
    func background(content: Content) -> some View {
        if #available(iOS 16.0, *) {
            content
                .scrollContentBackground(.hidden)
                .background(TokenColors.Background.page.swiftUI)
        } else {
            content
                .background(TokenColors.Background.page.swiftUI)
        }
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
