import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADomain

public extension PromoLandingDialogContentView {
    struct Dependency {
        let plan: PlanEntity
        let planPurchaser: any PlanPurchasing
        let dismissAction: @MainActor () -> Void
        let onPurchased: @MainActor () -> Void

        public init(
            plan: PlanEntity,
            planPurchaser: some PlanPurchasing,
            dismissAction: @escaping @MainActor () -> Void,
            onPurchased: @escaping @MainActor () -> Void = {}
        ) {
            self.plan = plan
            self.planPurchaser = planPurchaser
            self.dismissAction = dismissAction
            self.onPurchased = onPurchased
        }
    }
}
