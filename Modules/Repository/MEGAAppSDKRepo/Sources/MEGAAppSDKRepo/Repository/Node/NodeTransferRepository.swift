import MEGADomain
import MEGASdk
import MEGASwift

public struct NodeTransferRepository: NodeTransferRepositoryProtocol {
    public static var newRepo: NodeTransferRepository {
        NodeTransferRepository()
    }
    
    public var transferStarUpdates: AnyAsyncSequence<TransferEntity> {
        MEGAUpdateHandlerManager.shared.transferStarUpdates
    }
    
    public var transferUpdates: AnyAsyncSequence<TransferEntity> {
        MEGAUpdateHandlerManager.shared.transferUpdates
    }
    
    public var transferTemporaryErrorUpdates: AnyAsyncSequence<TransferResponseEntity> {
        MEGAUpdateHandlerManager.shared.transferTemporaryErrorUpdates
    }
    
    public var transferFinishUpdates: AnyAsyncSequence<TransferResponseEntity> {
        MEGAUpdateHandlerManager.shared.transferFinishUpdates
    }
}
