import SwiftUI

struct ScrollableWhenTallerThanContainerModifier: ViewModifier {
    let defaultScrollAnchor: UnitPoint?

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
            .defaultScrollAnchor(defaultScrollAnchor)
        }
    }
}

public extension View {
    /// Allows scrolling when content exceeds container height.
    func scrollableWhenTallerThanContainer(
        defaultScrollAnchor: UnitPoint? = nil
    ) -> some View {
        modifier(ScrollableWhenTallerThanContainerModifier(
            defaultScrollAnchor: defaultScrollAnchor
        ))
    }
}
