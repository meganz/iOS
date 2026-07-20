import MEGASwiftUI
import MEGAUIComponent
import SwiftUI

/// Renders the dialog for a given `QuotaDialogViewModel`, shared by the storage and transfer entry points
/// (which differ only in the mapper their view model was built with).
struct QuotaDialogContentView: View {
    @ObservedObject var viewModel: QuotaDialogViewModel
    let onClose: () -> Void

    var body: some View {
        dialog
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: onClose) {
                        XmarkCloseButton()
                    }
                }
            }
            .onFirstLoad { await viewModel.load() }
    }

    @ViewBuilder private var dialog: some View {
        switch viewModel.viewState {
        case .loading:
            QuotaDialogSkeletonView()
        case .error:
            QuotaDialogErrorView()
        case let .upgradeAvailable(header, currentPlan, recommendedPlan):
            QuotaDialogView(
                header: { QuotaDialogHeaderView(header: header) },
                currentPlanCard: { CurrentPlanView(currentPlan: currentPlan) },
                recommendedPlanCard: { RecommendedPlanView(plan: recommendedPlan) },
                footer: { RecommendedPlanFooterView(planName: recommendedPlan.name) }
            )
        case let .noUpgradeAvailable(header, currentPlan):
            QuotaDialogView(
                header: { QuotaDialogHeaderView(header: header) },
                currentPlanCard: { CurrentPlanView(currentPlan: currentPlan) },
                footer: { ContactSupportFooterView() }
            )
        }
    }
}
