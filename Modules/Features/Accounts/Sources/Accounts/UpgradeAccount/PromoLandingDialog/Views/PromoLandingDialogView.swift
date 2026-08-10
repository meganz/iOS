import MEGASwiftUI
import SwiftUI

/// The promotional offer landing dialog for a user-triggered entry point: it opens on the skeleton,
/// loads, then swaps to the offer or to the error state.
public struct PromoLandingDialogView: View {
    @StateObject private var viewModel: PromoLandingDialogViewModel

    public init(dependency: PromoLandingDialogDependency) {
        _viewModel = StateObject(wrappedValue: PromoLandingDialogViewModel(dependency: dependency))
    }

    public var body: some View {
        content
            .onLoad { await viewModel.load() }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.viewState {
        case .loading:
            PromoLandingDialogLoadingView(dismissAction: { viewModel.dismiss() })
        case .error:
            PromoLandingDialogErrorView(
                dismissAction: { viewModel.dismiss() },
                retryAction: { await viewModel.load() }
            )
        case let .loaded(contentViewDependency):
            PromoLandingDialogContentView(dependency: contentViewDependency)
        }
    }
}
