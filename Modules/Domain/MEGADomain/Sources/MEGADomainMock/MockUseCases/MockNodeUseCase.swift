import MEGADomain
import MEGASwift

public final class MockNodeUseCase: NodeUseCaseProtocol, @unchecked Sendable {
    
    public enum Invocation: Sendable, Equatable {
        case isDownloaded
    }
    
    @Atomic public var invocations: [Invocation] = []
    
    public var nodeUpdates: AnyAsyncSequence<[NodeEntity]> {
        AsyncStream { continuation in
            continuation.yield(with: .success([]))
        }
        .eraseToAnyAsyncSequence()
    }
    
    private let isDownloaded: Bool
    
    public init(isDownloaded: Bool  = false) {
        self.isDownloaded = isDownloaded
    }
    
    public func rootNode() -> NodeEntity? {
        nil
    }
    
    public func nodeAccessLevel(nodeHandle: HandleEntity) -> NodeAccessTypeEntity {
        .unknown
    }
    
    public func nodeAccessLevelAsync(nodeHandle: HandleEntity) async -> NodeAccessTypeEntity {
        .unknown
    }
    
    public func labelString(label: NodeLabelTypeEntity) -> String {
        label.labelString
    }
    
    public func getFilesAndFolders(nodeHandle: HandleEntity) -> (childFileCount: Int, childFolderCount: Int) {
        (0, 0)
    }
    
    public func sizeFor(node: NodeEntity) -> UInt64? {
        nil
    }
    
    public func folderInfo(node: NodeEntity) async throws -> FolderInfoEntity? {
        nil
    }
    
    public func hasVersions(nodeHandle: HandleEntity) -> Bool {
        false
    }
    
    public func isDownloaded(nodeHandle: HandleEntity) -> Bool {
        $invocations.mutate { $0.append(.isDownloaded) }
        return isDownloaded
    }
    
    public func isARubbishBinRootNode(nodeHandle: HandleEntity) -> Bool {
        false
    }
    
    public func isInRubbishBin(nodeHandle: HandleEntity) -> Bool {
        false
    }
    
    public func nodeForHandle(_ handle: HandleEntity) -> NodeEntity? {
        nil
    }
    
    public func parentForHandle(_ handle: HandleEntity) -> NodeEntity? {
        nil
    }
    
    public func parentsForHandle(_ handle: HandleEntity) async -> [NodeEntity]? {
        nil
    }
    
    public func asyncChildrenOf(node: NodeEntity, sortOrder: SortOrderEntity) async -> NodeListEntity? {
        nil
    }
    
    public func childrenOf(node: NodeEntity) -> NodeListEntity? {
        nil
    }
    
    public func childrenNamesOf(node: NodeEntity) -> [String]? {
        nil
    }
    
    public func isRubbishBinRoot(node: NodeEntity) -> Bool {
        false
    }
    
    public func isRestorable(node: NodeEntity) -> Bool {
        false
    }
    
    public func createFolder(with name: String, in parent: NodeEntity) async throws -> NodeEntity {
        throw GenericErrorEntity()
    }
}
