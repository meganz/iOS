import MEGADomain
import MEGASdk
import MEGASwift

public final class NodeTransferRepository: NSObject, NodeTransferRepositoryProtocol {
    public static var newRepo: NodeTransferRepository {
        NodeTransferRepository(
            nodeTransferCompletionUpdatesProvider: NodeTransferCompletionUpdatesProvider(
                sdk: MEGASdk.sharedSdk,
                sharedFolderSdk: MEGASdk.sharedFolderLinkSdk
            )
        )
    }
    
    public var nodeTransferCompletionUpdates: AnyAsyncSequence<TransferEntity> {
        nodeTransferCompletionUpdatesProvider.nodeTransferUpdates
    }
    
    private let nodeTransferCompletionUpdatesProvider: any NodeTransferCompletionUpdatesProviderProtocol
    
    public init(
        nodeTransferCompletionUpdatesProvider: some NodeTransferCompletionUpdatesProviderProtocol
    ) {
        self.nodeTransferCompletionUpdatesProvider = nodeTransferCompletionUpdatesProvider
    }
}
