import SwiftUI

struct SearchResultTapAndLongPressGestureModifier: ViewModifier {
    private enum Constants {
        static let easeInOutDuration = 0.05
        static let longPressMininumDuration = 0.5
        static let tapHighlightDurationNs: UInt64 = 100_000_000
    }

    let isHighlighted: Binding<Bool>
    let viewModel: SearchResultRowViewModel

    func body(content: Content) -> some View {
        content
            .onTapGesture {
                withAnimation(.easeInOut(duration: Constants.easeInOutDuration)) {
                    isHighlighted.wrappedValue = true
                }

                Task {
                    // Wait for Constants.tapHighlightDurationNs to keep `isHighlighted.wrappedValue = true`
                    // for a little before setting it to false ot dismiss the highlight effect
                    try await Task.sleep(nanoseconds: Constants.tapHighlightDurationNs)
                    withAnimation(.easeInOut(duration: Constants.easeInOutDuration)) {
                        isHighlighted.wrappedValue = false
                    }
                }

                viewModel.actions.selectionAction()
            }
            .onLongPressGesture(minimumDuration: Constants.longPressMininumDuration) {
                viewModel.actions.revampLongPress()
                isHighlighted.wrappedValue = false
            } onPressingChanged: { pressing in
                withAnimation(.easeInOut(duration: Constants.easeInOutDuration)) {
                    isHighlighted.wrappedValue = pressing
                }
            }
    }
}

extension View {

    /// Convenient method to apply  tap gesture and long press gesture of SearchResultRowViewModel to a View
    /// - Parameters:
    ///   - viewModel: The viewModel for handling the tap and long press gestures
    ///   - isHighlighted: Binding<Bool> to trigger the highlighting of the view
    /// - Returns: The view with gestures applied
    func applyTapAndLongPressFromRowViewModel(_ viewModel: SearchResultRowViewModel, isHighlighted: Binding<Bool>) -> some View {
        modifier(SearchResultTapAndLongPressGestureModifier(isHighlighted: isHighlighted, viewModel: viewModel))
    }
}
