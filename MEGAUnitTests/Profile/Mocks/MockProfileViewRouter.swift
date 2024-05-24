import Accounts
@testable import MEGA
import MEGADomain

final class MockProfileViewRouter: ProfileViewRouting {
    var showCancelSubscriptionFlow_calledTimes = 0
    
    func showCancelSubscriptionFlow(accountDetails: AccountDetailsEntity, assets: CurrentPlanDetailAssets) {
        showCancelSubscriptionFlow_calledTimes += 1
    }
}
