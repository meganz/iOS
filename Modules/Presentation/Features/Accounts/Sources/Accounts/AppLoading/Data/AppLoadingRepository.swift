import MEGADomain
import MEGASdk

struct AppLoadingRepository: AppLoadingRepositoryProtocol {
    static var newRepo: AppLoadingRepository {
        AppLoadingRepository(sdk: MEGASdk.sharedSdk)
    }
    
    var waitingReason: WaitingReasonEntity {
        sdk.waiting.toWaitingReasonEntity()
    }
    
    let sdk: MEGASdk
    
    init(sdk: MEGASdk) {
        self.sdk = sdk
    }
}
