import MEGAAppPresentation
import MEGADesignToken
import MEGADomain
import MEGASwiftUI
import MEGAUIComponent
import SwiftUI

/// Renders the dialog for a given `QuotaDialogViewModel`, shared by the storage and transfer entry points
/// (which differ only in the mapper their view model was built with).
struct QuotaDialogContentView: View {
    struct Dependency {
        let useCase: any QuotaDialogUseCaseProtocol
        let mapper: any QuotaDialogMapping
        let planPurchaser: any PlanPurchasing
        /// Injected rather than reached for via `DIContainer` so the previews and the QA simulator can drive the dialog without sending real events.
        let tracker: any AnalyticsTracking

        func trackingUseCase(
            kind: QuotaWarningDialogView.Kind,
            isFreeUser: Bool
        ) -> QuotaDialogTrackingUseCase {
            QuotaDialogTrackingUseCase(kind: kind, isFreeUser: isFreeUser, tracker: tracker)
        }

        func upgradableFooterDependency(
            kind: QuotaWarningDialogView.Kind,
            isFreeUser: Bool
        ) -> RecommendedPlanFooterView.Dependency {
            RecommendedPlanFooterView.Dependency(
                planPurchaser: planPurchaser,
                trackingUseCase: trackingUseCase(kind: kind, isFreeUser: isFreeUser)
            )
        }
    }

    @StateObject private var viewModel: QuotaDialogViewModel

    private let dependency: QuotaDialogContentView.Dependency
    private let kind: QuotaWarningDialogView.Kind
    private let onClose: @MainActor () -> Void
    private let onViewAllPlans: @MainActor () -> Void

    init(
        dependency: QuotaDialogContentView.Dependency,
        kind: QuotaWarningDialogView.Kind,
        onClose: @escaping @MainActor () -> Void,
        onViewAllPlans: @escaping @MainActor () -> Void
    ) {
        _viewModel = StateObject(wrappedValue: QuotaDialogViewModel(
            useCase: dependency.useCase,
            mapper: dependency.mapper
        ))
        self.dependency = dependency
        self.kind = kind
        self.onClose = onClose
        self.onViewAllPlans = onViewAllPlans
    }

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
            QuotaDialogErrorView(onRetry: { Task { await viewModel.retry() } })
        case let .upgradeAvailable(header, currentPlan, recommendedPlan):
            QuotaDialogView(
                trackingUseCase: dependency.trackingUseCase(kind: kind, isFreeUser: currentPlan.freeUser),
                header: { QuotaDialogHeaderView(header: header) },
                currentPlanCard: { CurrentPlanView(currentPlan: currentPlan) },
                recommendedPlanCard: { RecommendedPlanView(plan: recommendedPlan) },
                footer: {
                    RecommendedPlanFooterView(
                        recommendedPlan: recommendedPlan,
                        dependency: dependency.upgradableFooterDependency(kind: kind, isFreeUser: currentPlan.freeUser),
                        onPurchased: onClose,
                        onViewAllPlans: onViewAllPlans
                    )
                }
            )
        case let .noUpgradeAvailable(header, currentPlan):
            QuotaDialogView(
                trackingUseCase: dependency.trackingUseCase(kind: kind, isFreeUser: currentPlan.freeUser),
                header: { QuotaDialogHeaderView(header: header) },
                currentPlanCard: { CurrentPlanView(currentPlan: currentPlan) },
                footer: { ContactSupportFooterView() }
            )
        }
    }
}
