import MEGASwiftUI
import SwiftUI

/// Top-level redesigned Upgrade screen. Drives the loading skeleton, the load
/// error dialog, and the promo-vs-standard swap. Each loaded content view model
/// carries its own purchase alerts / snackbar via `revampContentPresentation`.
public struct UpgradePlansContainerView: View {
    @StateObject private var viewModel: UpgradePlansContainerViewModel

    public init(dependency: RevampUpgradePlansDependency) {
        _viewModel = StateObject(wrappedValue: UpgradePlansContainerViewModel(dependency: dependency))
    }

    public var body: some View {
        content
            .onLoad {
                await viewModel.loadData()
                await viewModel.monitorPromoExpiry()
            }
            .onAppear { viewModel.onAppear() }
            .onReceive(viewModel.$isDismiss) { isDismiss in
                if isDismiss { viewModel.dependency.dismissAction() }
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
            SubscriptionStandardView(
                dependency: viewModel.dependency,
                viewModel: contentViewModel,
                dismissAction: { viewModel.dismiss() }
            )
        case .promo(let contentViewModel):
            SubscriptionPromoView(
                dependency: viewModel.dependency,
                viewModel: contentViewModel,
                dismissAction: { viewModel.dismiss() }
            )
        }
    }
}
