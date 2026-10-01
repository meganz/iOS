import SwiftUI

struct ScrollableWhenTallerThanContainerModifier: ViewModifier {
    func body(content: Content) -> some View {
        GeometryReader { proxy in
            ScrollView {
                content
                    .frame(
                        maxWidth: .infinity,
                        minHeight: proxy.size.height // Centers short content
                    )
            }
            .scrollBounceBehavior(.basedOnSize)
        }
    }
}

public extension View {
    /// Allows scrolling when content exceeds container height.
    func scrollableWhenTallerThanContainer() -> some View {
        modifier(ScrollableWhenTallerThanContainerModifier())
    }
}
