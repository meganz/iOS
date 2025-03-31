import MEGADomain
import MEGASdk
import MEGASwift

public struct NodeTransferRepository: NodeTransferRepositoryProtocol {
    public static var newRepo: NodeTransferRepository {
        NodeTransferRepository()
    }
    
    public var transferFinishUpdates: AnyAsyncSequence<Result<TransferEntity, ErrorEntity>> {
        MEGAUpdateHandlerManager.shared.transferFinishUpdates
    }
}
