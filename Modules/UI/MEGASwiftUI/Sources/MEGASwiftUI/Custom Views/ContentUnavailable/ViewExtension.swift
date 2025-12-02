import SwiftUI

extension View {
    public func emptyState(
        _ viewModel: ContentUnavailableViewModel?,
        usesRevampLayout: Bool = false
    ) -> some View {
        modifier(EmptyStateViewModifier(emptyViewModel: viewModel, usesRevampLayout: usesRevampLayout))
    }
}

struct EmptyStateViewModifier: ViewModifier {
    let emptyViewModel: ContentUnavailableViewModel?
    let usesRevampLayout: Bool

    func body(content: Content) -> some View {
        if let emptyViewModel {
            content
                .overlay(
                    emptyOverlay(viewModel: emptyViewModel)
                )
        } else {
            content
        }
    }

    @ViewBuilder
    func emptyOverlay(viewModel: ContentUnavailableViewModel) -> some View {
        if usesRevampLayout {
            RevampedContentUnavailableView(viewModel: viewModel)
        } else {
            ContentUnavailableView(viewModel: viewModel)
        }
    }
}

struct RevampedEmptyStateViewModifier: ViewModifier {
    var emptyViewModel: ContentUnavailableViewModel?

    func body(content: Content) -> some View {
        if let emptyViewModel {
            content
                .overlay(
                    RevampedContentUnavailableView(viewModel: emptyViewModel)
                )
        } else {
            content
        }
    }
}
