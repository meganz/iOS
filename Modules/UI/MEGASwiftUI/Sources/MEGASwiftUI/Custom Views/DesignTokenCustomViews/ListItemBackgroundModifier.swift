import MEGADesignToken
import SwiftUI

public struct ListItemBackgroundModifier: ViewModifier {
    public func body(content: Content) -> some View {
        background(content: content)
    }

    @ViewBuilder
    func background(content: Content) -> some View {
        content
            .listRowBackground(TokenColors.Background.page.swiftUI)
    }
}

public extension View {
    @ViewBuilder
    func listItemBackground() -> some View {
        modifier(ListItemBackgroundModifier())
    }
}
