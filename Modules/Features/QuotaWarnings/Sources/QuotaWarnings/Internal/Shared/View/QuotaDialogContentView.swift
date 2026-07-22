import MEGADesignToken
import MEGASwiftUI
import MEGAUIComponent
import SwiftUI

/// Renders the dialog for a given `QuotaDialogViewModel`, shared by the storage and transfer entry points
/// (which differ only in the mapper their view model was built with).
struct QuotaDialogContentView: View {
    @ObservedObject var viewModel: QuotaDialogViewModel
    let onClose: () -> Void
    let onViewAllPlans: @MainActor () -> Void

    var body: some View {
        dialog
            .safeAreaInset(edge: .top, spacing: 0) {
                QuotaDialogTopBar(onClose: onClose)
                    .ignoresSafeArea(edges: .top)
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
                footer: { RecommendedPlanFooterView(planName: recommendedPlan.name, onViewAllPlans: onViewAllPlans) }
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
