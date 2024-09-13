import MEGADesignToken
import MEGADomain
import MEGAL10n
import MEGASDKRepo
import Settings

extension UpgradeTableViewController {
    
    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        tableView.sizeFooterToFit()
    }
    
    @objc func createUpgradeAccountViewModel() -> UpgradeAccountViewModel {
        UpgradeAccountViewModel(accountPlanAnalyticsUsecase: AccountPlanAnalyticsUseCase(repository: AnalyticsRepository.newRepo))
    }
    
    @objc func setCurrentPlanMaxQuotaData() {
        guard let accountDetails = MEGASdk.shared.mnz_accountDetails else {
            return
        }
        
        let storageMax = String.memoryStyleString(fromByteCount: accountDetails.storageMax)
        let transferMax = String.memoryStyleString(fromByteCount: accountDetails.transferMax)
        currentPlanStorageLabel.attributedText = quotaAttributedText(maxQuota: storageMax, fullQuotaString: Strings.Localizable.Account.storageQuota(storageMax))
        currentPlanBandwidthLabel.attributedText = quotaAttributedText(maxQuota: transferMax, fullQuotaString: Strings.Localizable.Account.storageQuota(transferMax))
    }
    
    private func quotaAttributedText(maxQuota: String, fullQuotaString: String) -> NSMutableAttributedString {
        let attributedQuota = NSMutableAttributedString(
            string: fullQuotaString,
            attributes: [.font: UIFont.preferredFont(style: .caption1, weight: .medium),
                         .foregroundColor: secondaryTextColor]
        )
        
        if let maxQuotaRange = fullQuotaString.range(of: maxQuota) {
            attributedQuota.addAttributes(
                [.foregroundColor: primaryTextColor],
                range: NSRange(maxQuotaRange, in: fullQuotaString)
            )
        }
        return attributedQuota
    }
    
    // MARK: - Terms and policies
    @objc func showTermsAndPolicies() {
        TermsAndPoliciesRouter(
            accountUseCase: AccountUseCase(repository: AccountRepository.newRepo),
            navigationController: navigationController
        ).start()
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
    
    // MARK: - Token colors
    
    @objc var whiteTextColor: UIColor {
        TokenColors.Text.onColor
    }
    
    @objc var primaryTextColor: UIColor {
        TokenColors.Text.primary
    }
    
    @objc var secondaryTextColor: UIColor {
        TokenColors.Text.secondary
    }
    
    @objc var footerTextColor: UIColor {
        TokenColors.Text.secondary
    }
    
    @objc var defaultBackgroundColor: UIColor {
        TokenColors.Background.page
    }
    
    @objc var headerBackgroundColor: UIColor {
        TokenColors.Background.page
    }
    
    @objc var currentPlanBackgroundColor: UIColor {
        TokenColors.Background.page
    }
    
    @objc var separatorColor: UIColor {
        TokenColors.Border.strong
    }
    
    @objc var linkColor: UIColor {
        TokenColors.Link.primary
    }
}
