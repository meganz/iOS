@testable import MEGA
import MEGADomain
import MEGASDKRepo
import MEGASwift

struct MockAccountPlanPurchaseUpdatesProvider: AccountPlanPurchaseUpdatesProviderProtocol {
    var purchasePlanResultUpdates: AnyAsyncSequence<Result<Void, AccountPlanErrorEntity>>
    var restorePurchaseUpdates: AnyAsyncSequence<RestorePurchaseStateEntity>

    init(
        purchasePlanResultUpdates: AnyAsyncSequence<Result<Void, AccountPlanErrorEntity>> = EmptyAsyncSequence().eraseToAnyAsyncSequence(),
        restorePurchaseUpdates: AnyAsyncSequence<RestorePurchaseStateEntity> = EmptyAsyncSequence().eraseToAnyAsyncSequence()
    ) {
        self.purchasePlanResultUpdates = purchasePlanResultUpdates
        self.restorePurchaseUpdates = restorePurchaseUpdates
    }
}
