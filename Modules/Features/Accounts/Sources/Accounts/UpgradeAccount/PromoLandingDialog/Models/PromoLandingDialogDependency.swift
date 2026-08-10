import MEGAAppPresentation
import MEGADomain

public struct PromoLandingDialogDependency {
    let checksForExpiry: Bool
    let promotedPlanUseCase: any PromotedPlanUseCaseProtocol
    let planPurchaser: any PlanPurchasing
    let dismissAction: @MainActor () -> Void
    let onPurchased: @MainActor () -> Void

    public init(
        checksForExpiry: Bool,
        promotedPlanUseCase: any PromotedPlanUseCaseProtocol,
        planPurchaser: some PlanPurchasing,
        dismissAction: @MainActor @escaping () -> Void,
        onPurchased: @MainActor @escaping () -> Void = {}
    ) {
        self.checksForExpiry = checksForExpiry
        self.promotedPlanUseCase = promotedPlanUseCase
        self.planPurchaser = planPurchaser
        self.dismissAction = dismissAction
        self.onPurchased = onPurchased
    }

    /// Carries this dependency over to the loaded dialog, once the offer has been resolved.
    func contentViewDependency(for plan: PlanEntity) -> PromoLandingDialogContentView.Dependency {
        PromoLandingDialogContentView.Dependency(
            plan: plan,
            planPurchaser: planPurchaser,
            dismissAction: dismissAction,
            onPurchased: onPurchased
        )
    }
}
