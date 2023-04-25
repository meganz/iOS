
@MainActor
final class MyAccountHallPlanViewModel {
    let router: UpgradeAccountRouter
    let currentPlan: String
    
    init(currentPlan: String, router: UpgradeAccountRouter) {
        self.currentPlan = currentPlan
        self.router = router
    }
    
    func tappedUpgradeButton() {
        router.presentUpgradeTVC()
    }
}
