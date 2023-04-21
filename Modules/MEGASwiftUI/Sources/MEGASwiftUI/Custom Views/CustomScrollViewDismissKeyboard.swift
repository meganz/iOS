import SwiftUI

@available(iOS 16, *)
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
        if #available(iOS 16, *) {
            self.modifier(ScrollViewDismissKeyboardInteractivelyModifier())
        }
        else {
            self.modifier(ScrollViewDismissKeyboardOnDragModifier())
        }
    }
}
