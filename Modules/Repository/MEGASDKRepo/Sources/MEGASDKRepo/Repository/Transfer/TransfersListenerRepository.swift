import MEGADomain
import MEGASdk
import MEGASwift

public struct TransfersListenerRepository: TransfersListenerRepositoryProtocol {
    public var completedTransfers: AnyAsyncSequence<TransferEntity> {
        AsyncStream { continuation in
            let delegate = PrivateTransferDelegate {
                continuation.yield($0)
            }
            continuation.onTermination = { @Sendable _ in
                sdk.remove(delegate)
            }
            sdk.add(delegate, queueType: .main)
        }.eraseToAnyAsyncSequence()
    }
    
    private let sdk: MEGASdk
    
    public init(sdk: MEGASdk) {
        self.sdk = sdk
    }
    
    public func pauseTransfers() {
        sdk.pauseTransfers(true)
    }
    
    public func resumeTransfers() {
        sdk.pauseTransfers(false)
    }
}

private final class PrivateTransferDelegate: NSObject, MEGATransferDelegate, Sendable {
    private let onTransferFinish: @Sendable (TransferEntity) -> Void
    
    init(onTransferFinish: @Sendable @escaping (TransferEntity) -> Void) {
        self.onTransferFinish = onTransferFinish
    }
    
    func onTransferFinish(_ api: MEGASdk, transfer: MEGATransfer, error: MEGAError) {
        onTransferFinish(transfer.toTransferEntity())
    }
}

public extension TransfersListenerRepository {
    static var newRepo: TransfersListenerRepository {
        .init(sdk: MEGASdk.sharedSdk)
    }
}
