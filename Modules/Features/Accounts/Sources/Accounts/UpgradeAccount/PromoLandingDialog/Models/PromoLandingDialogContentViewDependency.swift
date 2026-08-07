import MEGAAppPresentation

struct PromoLandingDialogContentViewDependency {
    let planPurchaser: any PlanPurchasing
    let dismissAction: @MainActor () -> Void
    let onPurchased: @MainActor () -> Void
    let header: SubscriptionPromoHeaderViewModel
    let card: SubscriptionRevampPromoPlanCardModel

    init(
        planPurchaser: some PlanPurchasing,
        dismissAction: @escaping @MainActor () -> Void,
        onPurchased: @escaping @MainActor () -> Void,
        header: SubscriptionPromoHeaderViewModel,
        card: SubscriptionRevampPromoPlanCardModel
    ) {
        self.planPurchaser = planPurchaser
        self.dismissAction = dismissAction
        self.onPurchased = onPurchased
        self.header = header
        self.card = card
    }
}
