import SwiftUI

extension View {
    public func emptyState(
        _ viewModel: ContentUnavailableViewModel?
    ) -> some View {
        modifier(EmptyStateViewModifier(emptyViewModel: viewModel))
    }
}

struct EmptyStateViewModifier: ViewModifier {
    var emptyViewModel: ContentUnavailableViewModel?
    
    func body(content: Content) -> some View {
        if let emptyViewModel {
            content
                .overlay(
                    ContentUnavailableView(viewModel: emptyViewModel)
                )
        } else {
            content
        }
    }
}
