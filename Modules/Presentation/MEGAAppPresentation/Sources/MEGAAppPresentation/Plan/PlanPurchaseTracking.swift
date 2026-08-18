
/// Needed to bridge the upgrade screen's analytics into `PlanPurchaseViewModel` which lives
/// in MEGAPresentation while the actual tracking logic resides in MEGAAccount
public protocol PlanPurchaseTracking: Sendable {
    func trackBuyPlan(productIdentifier: String)
}
