import MEGADomain
import MEGASdk
import MEGASwift

public protocol NodeTransferCompletionUpdatesProviderProtocol: Sendable {
    /// Node updates from `MEGATransferDelegate` `onTransferFinish` as an `AnyAsyncSequence`
    ///
    /// - Returns: `AnyAsyncSequence` that will call sdk.add on creation and sdk.remove onTermination of `AsyncStream`.
    /// It will yield `TransferEntity` items until sequence terminated
    var nodeTransferUpdates: AnyAsyncSequence<TransferEntity> { get }
}

public struct NodeTransferCompletionUpdatesProvider: NodeTransferCompletionUpdatesProviderProtocol {
    public var nodeTransferUpdates: AnyAsyncSequence<TransferEntity> {
        AsyncStream { continuation in
            let delegate = NodeTransferDelegate {
                continuation.yield($0)
            }
            
            continuation.onTermination = { _ in
                sdk.remove(delegate)
                sharedFolderSdk.remove(delegate)
            }
            sdk.add(delegate)
            sharedFolderSdk.add(delegate)
        }
        .eraseToAnyAsyncSequence()
    }
    
    private let sdk: MEGASdk
    private let sharedFolderSdk: MEGASdk
    
    public init(sdk: MEGASdk, sharedFolderSdk: MEGASdk) {
        self.sdk = sdk
        self.sharedFolderSdk = sharedFolderSdk
    }
}

private class NodeTransferDelegate: NSObject, MEGATransferDelegate {
    private let onTransferFinish: (TransferEntity) -> Void
    
    init(onTransferFinish: @escaping (TransferEntity) -> Void) {
        self.onTransferFinish = onTransferFinish
        super.init()
    }
    
    func onTransferFinish(_ api: MEGASdk, transfer: MEGATransfer, error: MEGAError) {
        guard error.type == .apiOk else { return }
        
        onTransferFinish(transfer.toTransferEntity())
    }
}
