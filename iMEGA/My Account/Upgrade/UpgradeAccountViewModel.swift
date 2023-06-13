import MEGADomain

final class UpgradeAccountViewModel: NSObject {
    private var accountPlanAnalyticsUsecase: any AccountPlanAnalyticsUseCaseProtocol
    
    init(accountPlanAnalyticsUsecase: any AccountPlanAnalyticsUseCaseProtocol) {
        self.accountPlanAnalyticsUsecase = accountPlanAnalyticsUsecase
    }
    
    @objc func sendAccountPlanTapStats(_ accountType: MEGAAccountType) {
        accountPlanAnalyticsUsecase.sendAccountPlanTapStats(plan: accountType.toAccountTypeEntity())
    }
}
