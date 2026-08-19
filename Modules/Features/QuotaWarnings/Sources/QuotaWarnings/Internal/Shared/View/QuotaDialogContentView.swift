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
            audience: QuotaDialogAudience
        ) -> QuotaDialogTrackingUseCase {
            QuotaDialogTrackingUseCase(kind: kind, audience: audience, tracker: tracker)
        }

        func upgradableFooterDependency(
            kind: QuotaWarningDialogView.Kind,
            audience: QuotaDialogAudience
        ) -> RecommendedPlanFooterView.Dependency {
            RecommendedPlanFooterView.Dependency(
                planPurchaser: planPurchaser,
                trackingUseCase: trackingUseCase(kind: kind, audience: audience)
            )
        }
    }

    @StateObject private var viewModel: QuotaDialogViewModel

    private let dependency: QuotaDialogContentView.Dependency
    private let kind: QuotaWarningDialogView.Kind
    private let onClose: @MainActor () -> Void
    private let onViewAllPlans: @MainActor () -> Void
    private let onSignIn: @MainActor () -> Void

    init(
        dependency: QuotaDialogContentView.Dependency,
        kind: QuotaWarningDialogView.Kind,
        onClose: @escaping @MainActor () -> Void,
        onViewAllPlans: @escaping @MainActor () -> Void,
        onSignIn: @escaping @MainActor () -> Void
    ) {
        _viewModel = StateObject(wrappedValue: QuotaDialogViewModel(
            useCase: dependency.useCase,
            mapper: dependency.mapper
        ))
        self.dependency = dependency
        self.kind = kind
        self.onClose = onClose
        self.onViewAllPlans = onViewAllPlans
        self.onSignIn = onSignIn
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
        case let .upgradeAvailable(header, currentPlan, recommendedPlan, audience):
            QuotaDialogView(
                trackingUseCase: dependency.trackingUseCase(kind: kind, audience: audience),
                header: { QuotaDialogHeaderView(header: header) },
                currentPlanCard: { currentPlan.map(CurrentPlanView.init) },
                recommendedPlanCard: { RecommendedPlanView(plan: recommendedPlan) },
                footer: {
                    RecommendedPlanFooterView(
                        recommendedPlan: recommendedPlan,
                        dependency: dependency.upgradableFooterDependency(kind: kind, audience: audience),
                        onPurchased: onClose,
                        onViewAllPlans: onViewAllPlans
                    )
                }
            )
        case let .noUpgradeAvailable(header, currentPlan, supportEmail, audience):
            QuotaDialogView(
                trackingUseCase: dependency.trackingUseCase(kind: kind, audience: audience),
                header: { QuotaDialogHeaderView(header: header) },
                currentPlanCard: { currentPlan.map(CurrentPlanView.init) },
                footer: { ContactSupportFooterView(email: supportEmail) }
            )
        case let .signIn(header, recommendedPlan):
            let trackingUseCase = dependency.trackingUseCase(kind: kind, audience: .signedOut)
            QuotaDialogView(
                trackingUseCase: trackingUseCase,
                header: { QuotaDialogHeaderView(header: header) },
                recommendedPlanCard: { RecommendedPlanView(plan: recommendedPlan) },
                footer: {
                    SignedOutPlanFooterView(
                        recommendedPlan: recommendedPlan,
                        trackingUseCase: trackingUseCase,
                        onSignIn: onSignIn
                    )
                }
            )
        }
    }
}
