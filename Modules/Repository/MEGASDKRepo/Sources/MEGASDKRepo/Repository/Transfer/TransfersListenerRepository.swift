import MEGADomain
import MEGASdk
import MEGASwift

public struct TransfersListenerRepository: TransfersListenerRepositoryProtocol {
    public static var newRepo: TransfersListenerRepository {
        .init(sdk: MEGASdk.sharedSdk)
    }
    
    public var completedTransfers: AnyAsyncSequence<TransferEntity> {
        MEGAUpdateHandlerManager
            .shared
            .transferFinishUpdates
            .compactMap { try? $0.get() }
            .eraseToAnyAsyncSequence()
    }
    
    private let sdk: MEGASdk
    
    init(sdk: MEGASdk) {
        self.sdk = sdk
    }
    
    public func pauseTransfers() {
        sdk.pauseTransfers(true)
    }
    
    public func resumeTransfers() {
        sdk.pauseTransfers(false)
    }
}
