import MEGADomain
import MEGASwift

public struct MockRubbishBinRepository: RubbishBinRepositoryProtocol {
    private let syncDebrisNode: NodeEntity?
    private let syncDebrisChildNodes: [NodeEntity]?
    private let rubbishBinAutopurgeEnabled: Bool?
    
    public let onRubbishBinSettinghsRequestFinish: AnyAsyncSequence<Result<RubbishBinSettingsEntity, any Error>>
    
    public init(syncDebrisNode: NodeEntity? = nil,
                syncDebrisChildNodes: [NodeEntity]? = nil,
                rubbishBinAutopurgeEnabled: Bool? = nil,
                onRubbishBinSettinghsRequestFinish: AnyAsyncSequence<Result<RubbishBinSettingsEntity, any Error>> = EmptyAsyncSequence().eraseToAnyAsyncSequence()) {
        self.syncDebrisNode = syncDebrisNode
        self.syncDebrisChildNodes = syncDebrisChildNodes
        self.rubbishBinAutopurgeEnabled = rubbishBinAutopurgeEnabled
        self.onRubbishBinSettinghsRequestFinish = onRubbishBinSettinghsRequestFinish
    }
    
    private func isSyncDebrisRootNode(_ node: NodeEntity) -> Bool {
        syncDebrisNode == node
    }
    
    public func isSyncDebrisChild(_ node: NodeEntity) -> Bool {
        syncDebrisChildNodes?.contains(node) ?? false
    }
    
    public func isSyncDebrisNode(_ node: MEGADomain.NodeEntity) -> Bool {
        if isSyncDebrisRootNode(node) {
            return true
        } else {
            return isSyncDebrisChild(node)
        }
    }
    
    public func serverSideRubbishBinAutopurgeEnabled() -> Bool {
        rubbishBinAutopurgeEnabled ?? false
    }
    
    public func cleanRubbishBin() {}
}
