import MEGADomain
import MEGAData

extension UpgradeTableViewController {
    
    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        tableView.sizeFooterToFit()
    }
    
    @objc func createUpgradeAccountViewModel() -> UpgradeAccountViewModel {
        UpgradeAccountViewModel(accountPlanAnalyticsUsecase: AccountPlanAnalyticsUseCase(repository: AnalyticsRepository.newRepo))
    }
}

//MARK: - Product Plan
extension UpgradeTableViewController {
    @objc func getAvailableProductPlans() -> [NSNumber] {
        guard let products = MEGAPurchase.sharedInstance().products as? [SKProduct] else {
            return []
        }
    
        let availablePlans: [NSNumber] = products.map { product in
            var plan: MEGAAccountType
            if product.productIdentifier.contains("pro1") {
                plan = .proI
            } else if product.productIdentifier.contains("pro2") {
                plan = .proII
            } else if product.productIdentifier.contains("pro3") {
                plan = .proIII
            } else {
                plan = .lite
            }
            return NSNumber(value: plan.rawValue)
        }.removeDuplicatesWhileKeepingTheOriginalOrder()
        
        return availablePlans
    }
}
