import Accounts
@testable import MEGA
import MEGADomain

final class MockProfileViewRouter: ProfileViewRouting {
    var showCancelAccountPlan_calledTimes = 0
    var showCancellationSteps_calledTimes = 0
    var showRecoveryKey_calledTimes = 0
    
    func showCancelAccountPlan(currentSubscription: AccountSubscriptionEntity, currentPlan: PlanEntity, freeAccountStorageLimit: Int, assets: CancelAccountPlanAssets) {
        showCancelAccountPlan_calledTimes += 1
    }
    
    func showCancellationSteps() {
        showCancellationSteps_calledTimes += 1
    }
    
    func showRecoveryKey(saveMasterKeyCompletion: @escaping () -> Void) {
        showRecoveryKey_calledTimes += 1
    }
}
