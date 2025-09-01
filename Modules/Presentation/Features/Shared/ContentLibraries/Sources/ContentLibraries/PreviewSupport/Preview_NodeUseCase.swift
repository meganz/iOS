import MEGADomain
import MEGASwift

struct Preview_NodeUseCase: NodeUseCaseProtocol {
    func isNodeDecrypted(node: MEGADomain.NodeEntity) -> Bool { false }
    
    var nodeUpdates: AnyAsyncSequence<[NodeEntity]> {
        EmptyAsyncSequence().eraseToAnyAsyncSequence()
    }
    
    func rootNode() -> NodeEntity? { nil }
    
    func nodeAccessLevel(nodeHandle: HandleEntity) -> NodeAccessTypeEntity {
        .unknown
    }
    
    func nodeAccessLevelAsync(nodeHandle: HandleEntity) async -> NodeAccessTypeEntity {
        .unknown
    }
    
    func labelString(label: NodeLabelTypeEntity) -> String {
        ""
    }
    
    func getFilesAndFolders(nodeHandle: HandleEntity) -> (childFileCount: Int, childFolderCount: Int) {
        (0, 0)
    }
    
    func sizeFor(node: NodeEntity) -> UInt64? {
        nil
    }
    
    func folderInfo(node: NodeEntity) async throws -> FolderInfoEntity? {
        nil
    }
    
    func hasVersions(nodeHandle: HandleEntity) -> Bool {
        false
    }
    
    func isDownloaded(nodeHandle: HandleEntity) -> Bool {
        false
    }
    
    func isARubbishBinRootNode(nodeHandle: HandleEntity) -> Bool {
        false
    }
    
    func isInRubbishBin(nodeHandle: HandleEntity) -> Bool {
        false
    }
    
    func nodeForHandle(_ handle: HandleEntity) -> NodeEntity? {
        nil
    }
    
    func nodeForFileLink(_ fileLink: FileLinkEntity) async -> NodeEntity? {
        nil
    }
    
    func folderLinkInfo(_ folderLink: String) async throws -> FolderLinkInfoEntity? {
        nil
    }
    
    func parentForHandle(_ handle: HandleEntity) -> NodeEntity? {
        nil
    }
    
    func parentsForHandle(_ handle: HandleEntity) async -> [NodeEntity]? {
        nil
    }
    
    func asyncChildrenOf(node: NodeEntity, sortOrder: SortOrderEntity) async -> NodeListEntity? {
        nil
    }
    
    func childrenOf(node: NodeEntity) -> NodeListEntity? {
        nil
    }
    
    func childrenNamesOf(node: NodeEntity) -> [String]? {
        nil
    }
    
    func isRubbishBinRoot(node: NodeEntity) -> Bool {
        false
    }
    
    func isRestorable(node: NodeEntity) -> Bool {
        false
    }
    
    func createFolder(with name: String, in parent: NodeEntity) async throws -> NodeEntity {
        throw GenericErrorEntity()
    }
    
    func isInheritingSensitivity(node: NodeEntity) async throws -> Bool {
        false
    }
    
    func isInheritingSensitivity(node: NodeEntity) throws -> Bool {
        false
    }
    
    func monitorInheritedSensitivity(for node: NodeEntity) -> AnyAsyncThrowingSequence<Bool, any Error> {
        EmptyAsyncSequence().eraseToAnyAsyncThrowingSequence()
    }
    
    func sensitivityChanges(for node: NodeEntity) -> AnyAsyncSequence<Bool> {
        EmptyAsyncSequence().eraseToAnyAsyncSequence()
    }
    
    func isFileTakenDown(_ nodeHandle: MEGADomain.HandleEntity) async -> Bool {
        false
    }
}
