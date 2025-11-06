import MEGAAppPresentation
import MEGADomain
import MEGASwift

public final class Preview_NodeUseCase: NodeUseCaseProtocol {
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
    
    public func folderLinkInfo(_ folderLink: String) async throws -> FolderLinkInfoEntity? {
        nil
    }
    
    public func hasVersions(nodeHandle: HandleEntity) -> Bool {
        false
    }
    
    public func isDownloaded(nodeHandle: HandleEntity) -> Bool {
        isDownloaded
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
    
    public func nodeForFileLink(_ fileLink: FileLinkEntity) async -> NodeEntity? {
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
    
    public func isInheritingSensitivity(node: NodeEntity) async throws -> Bool {
        false
    }
    
    public func isInheritingSensitivity(node: NodeEntity) throws -> Bool {
        false
    }
    
    public func monitorInheritedSensitivity(for node: NodeEntity) -> AnyAsyncThrowingSequence<Bool, any Error> {
        AsyncThrowingStream { continuation in
            continuation.finish(throwing: GenericErrorEntity())
        }
        .eraseToAnyAsyncThrowingSequence()
    }
    
    public func sensitivityChanges(for node: NodeEntity) -> AnyAsyncSequence<Bool> {
        AsyncStream { continuation in
            continuation.yield(with: .success(false))
        }
        .eraseToAnyAsyncSequence()
    }
    
    public func mergeInheritedAndDirectSensitivityChanges(for node: NodeEntity) -> AnyAsyncThrowingSequence<Bool, any Error> {
        AsyncThrowingStream { continuation in
            continuation.finish(throwing: GenericErrorEntity())
        }
        .eraseToAnyAsyncThrowingSequence()
    }
    
    public func isFileTakenDown(_ nodeHandle: HandleEntity) async -> Bool {
        false
    }

    public func isNodeDecrypted(node: MEGADomain.NodeEntity, fromFolderLink: Bool) -> Bool {
        false
    }
}
