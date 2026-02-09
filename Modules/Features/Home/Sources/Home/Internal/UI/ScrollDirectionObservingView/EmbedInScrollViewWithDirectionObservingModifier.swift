import SwiftUI

public struct EmbedInScrollViewWithDirectionObservingModifier: ViewModifier {

    private let scrollViewCoordinateSpaceName = "ScrollView"
    private let scrollDirectionHandler: (_ isScrollingDown: Bool) -> Void

    @State private var isScrollingDown = false
    @State private var lastMinY: CGFloat = 0

    public init(
        scrollDirectionHandler: @escaping (_ isScrollingDown: Bool) -> Void
    ) {
        self.scrollDirectionHandler = scrollDirectionHandler
    }

    public func body(content: Content) -> some View {
        GeometryReader { outer in
            let outerHeight = outer.size.height

            ScrollView(.vertical) {
                content
                    .background {
                        GeometryReader { proxy in
                            let contentHeight = proxy.size.height
                            let minYinScrollViewCoordinate = proxy.frame(in: .named(scrollViewCoordinateSpaceName)).minY
                            let contentHeightGap = outerHeight - contentHeight
                            let minY = max(
                                min(0, minYinScrollViewCoordinate),
                                contentHeightGap
                            )
                            Color.clear
                                .onChange(of: minY) { newVal in
                                    // When contentSize's height is still smaller than scrollView's height, we disable scrolling down handler
                                    if contentHeightGap > 0 {
                                        isScrollingDown = false
                                        scrollDirectionHandler(isScrollingDown)
                                    } else if (isScrollingDown && newVal > lastMinY)
                                        || (!isScrollingDown && newVal < lastMinY) {
                                        isScrollingDown = newVal < lastMinY
                                        scrollDirectionHandler(isScrollingDown)
                                    }
                                    lastMinY = newVal
                                }
                        }
                    }
            }
            .coordinateSpace(name: scrollViewCoordinateSpaceName)
        }
    }
}

public extension View {
    func embedInScrollViewWithDirectionChangeHandler(
        _ handler: @escaping (_ isScrollingDown: Bool) -> Void
    ) -> some View {
        modifier(
            EmbedInScrollViewWithDirectionObservingModifier(
                scrollDirectionHandler: handler
            )
        )
    }
}

private struct ScrollOffsetPreferenceKey: PreferenceKey {
    static let defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
