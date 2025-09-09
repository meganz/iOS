import SwiftUI

struct ScrollViewDismissKeyboardInteractivelyModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .scrollDismissesKeyboard(.interactively)
    }
}
struct ScrollViewDismissKeyboardOnDragModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .onAppear {
                UIScrollView.appearance().keyboardDismissMode = .onDrag
            }
    }
}

public extension View {
    @ViewBuilder
    func customScrollViewDismissKeyboard() -> some View {
        self.modifier(ScrollViewDismissKeyboardInteractivelyModifier())
    }
}
