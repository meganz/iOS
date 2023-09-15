import SwiftUI

extension View {
    public func emptyState(_ viewModel: ContentUnavailableView_iOS16ViewModel?) -> some View {
        modifier(EmptyStateViewModifier(emptyViewModel: viewModel))
    }
}

struct EmptyStateViewModifier: ViewModifier {
    var emptyViewModel: ContentUnavailableView_iOS16ViewModel?
    
    func body(content: Content) -> some View {
        if let emptyViewModel {
            ContentUnavailableView_iOS16(viewModel: emptyViewModel)
        } else {
            content
        }
    }
}
