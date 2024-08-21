import Foundation
import MEGADomain

protocol NodeInfoUseCaseProtocol: Sendable {
    func node(fromHandle: HandleEntity) -> MEGANode?
    func childrenInfo(fromParentHandle: HandleEntity) -> [AudioPlayerItem]?
    func folderChildrenInfo(fromParentHandle: HandleEntity) -> [AudioPlayerItem]?
    func folderLinkLogout()
    
    /// Check if a node is taken down. For current user node, it check through `MEGANode.isTakenDown()`. For non current user node, it will check through `MEGASdk.sharedFolderLink.getDownloadUrl()`.
    /// - Parameters:
    ///   - node: node to check
    ///   - isFolderLink: a boolean to indicates node accessed from folder link or not
    /// - Returns: returns true if it is taken down, false if it is not taken down
    func isTakenDown(node: MEGANode, isFolderLink: Bool) async throws -> Bool
}

final class NodeInfoUseCase: NodeInfoUseCaseProtocol {
    private let nodeInfoRepository: any NodeInfoRepositoryProtocol
    
    init(nodeInfoRepository: some NodeInfoRepositoryProtocol = NodeInfoRepository()) {
        self.nodeInfoRepository = nodeInfoRepository
    }
    
    func node(fromHandle: HandleEntity) -> MEGANode? {
        nodeInfoRepository.node(fromHandle: fromHandle)
    }
    
    func childrenInfo(fromParentHandle: HandleEntity) -> [AudioPlayerItem]? {
        nodeInfoRepository.childrenInfo(fromParentHandle: fromParentHandle)
    }
    
    func folderChildrenInfo(fromParentHandle: HandleEntity) -> [AudioPlayerItem]? {
        nodeInfoRepository.folderChildrenInfo(fromParentHandle: fromParentHandle)
    }
    
    func folderLinkLogout() {
        nodeInfoRepository.folderLinkLogout()
    }
    
    func isTakenDown(node: MEGANode, isFolderLink: Bool) async throws -> Bool {
        guard isFolderLink else {
            return node.isTakenDown()
        }
        return try await nodeInfoRepository.isFolderLinkNodeTakenDown(node: node)
    }
}
