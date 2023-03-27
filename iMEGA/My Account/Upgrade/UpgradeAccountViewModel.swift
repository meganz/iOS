import MEGADomain

final class UpgradeAccountViewModel: NSObject {
    private var accountPlanAnalyticsUsecase: AccountPlanAnalyticsUseCaseProtocol
    
    init(accountPlanAnalyticsUsecase: AccountPlanAnalyticsUseCaseProtocol) {
        self.accountPlanAnalyticsUsecase = accountPlanAnalyticsUsecase
    }
    
    @objc func sendAccountPlanTapStats(_ accountType: MEGAAccountType) {
        accountPlanAnalyticsUsecase.sendAccountPlanTapStats(plan: accountType.toAccountTypeEntity())
    }
}
