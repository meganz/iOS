import MEGADomain
import MEGAL10n
import MEGASDKRepo

extension UpgradeTableViewController {
    
    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        tableView.sizeFooterToFit()
    }
    
    @objc func createUpgradeAccountViewModel() -> UpgradeAccountViewModel {
        UpgradeAccountViewModel(accountPlanAnalyticsUsecase: AccountPlanAnalyticsUseCase(repository: AnalyticsRepository.newRepo))
    }
    
    @objc func setCurrentPlanMaxQuotaData() {
        guard let accountDetails = MEGASdk.shared.mnz_accountDetails,
              let storage = accountDetails.storageMax as? Int64,
              let transfer = accountDetails.transferMax as? Int64 else {
            return
        }

        let storageMax = String.memoryStyleString(fromByteCount: storage)
        let transferMax = String.memoryStyleString(fromByteCount: transfer)
        currentPlanStorageLabel.attributedText = quotaAttributedText(maxQuota: storageMax, fullQuotaString: Strings.Localizable.Account.storageQuota(storageMax))
        currentPlanBandwidthLabel.attributedText = quotaAttributedText(maxQuota: transferMax, fullQuotaString: Strings.Localizable.Account.storageQuota(transferMax))
    }
    
    private func quotaAttributedText(maxQuota: String, fullQuotaString: String) -> NSMutableAttributedString {
        let attributedQuota = NSMutableAttributedString(
            string: fullQuotaString,
            attributes: [.font: UIFont.preferredFont(style: .caption1, weight: .medium),
                         .foregroundColor: UIColor.mnz_primaryGray(for: self.traitCollection)]
        )
        
        if let maxQuotaRange = fullQuotaString.range(of: maxQuota) {
            attributedQuota.addAttributes(
                [.foregroundColor: UIColor.mnz_label()],
                range: NSRange(maxQuotaRange, in: fullQuotaString)
            )
        }
        return attributedQuota
    }
}

// MARK: - Product Plan
extension UpgradeTableViewController {
    @objc func removePlanOnAvailablePlans(_ planType: MEGAAccountType) {
        let accountType = planType.rawValue
        guard proLevelsMutableArray.contains(accountType) else { return }
        proLevelsMutableArray.remove(accountType)
    }
    
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
