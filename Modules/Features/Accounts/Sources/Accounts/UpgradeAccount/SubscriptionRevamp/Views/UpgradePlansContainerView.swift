import MEGASwiftUI
import SwiftUI

/// Top-level redesigned Upgrade screen. Drives the loading skeleton, the load
/// error dialog, and the promo-vs-standard swap. Each loaded content view model
/// carries its own purchase alerts / snackbar via `revampContentPresentation`.
public struct UpgradePlansContainerView: View {
    @StateObject private var viewModel: RevampUpgradePlansContainerViewModel
    @Environment(\.dismiss) private var dismiss

    public init(viewModel: RevampUpgradePlansContainerViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    public var body: some View {
        content
            .task { await viewModel.loadData() }
            .onAppear { viewModel.onLoad() }
            .onReceive(viewModel.$isDismiss) { isDismiss in
                if isDismiss { dismiss() }
            }
            .alert(
                viewModel.alertType?.title ?? "",
                isPresented: $viewModel.isAlertPresented,
                presenting: viewModel.alertType
            ) { alertType in
                Button(alertType.primaryButtonTitle) {
                    alertType.primaryButtonAction?()
                }
                if let secondaryButtonTitle = alertType.secondaryButtonTitle {
                    Button(secondaryButtonTitle, role: .cancel) {}
                }
            } message: { alertType in
                Text(alertType.message)
            }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.viewState {
        case .loading:
            SubscriptionRevampLoadingView()
        case .standard(let contentViewModel):
            SubscriptionRevampStandardView(viewModel: contentViewModel)
        case .promo(let contentViewModel):
            SubscriptionRevampPromoView(viewModel: contentViewModel)
        }
    }
}
