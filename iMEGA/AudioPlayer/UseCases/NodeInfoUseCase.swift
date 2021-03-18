import Foundation

protocol NodeInfoUseCaseProtocol {
    func node(fromHandle: MEGAHandle) -> MEGANode?
    func folderAuthNode(fromHandle: MEGAHandle) -> MEGANode?
    func path(fromHandle: MEGAHandle) -> URL?
    func childrenInfo(fromParentHandle: MEGAHandle) -> [AudioPlayerItem]?
    func folderChildrenInfo(fromParentHandle: MEGAHandle) -> [AudioPlayerItem]?
    func info(fromNode: MEGANode) -> AudioPlayerItem?
    func publicNode(fromFileLink: String, completion: @escaping ((MEGANode?) -> Void))
    func loginToFolder(link: String)
    func folderLinkLogout()
}

final class NodeInfoUseCase: NodeInfoUseCaseProtocol {
    private var nodeInfoRepository: NodeInfoRepositoryProtocol
    
    init(nodeInfoRepository: NodeInfoRepositoryProtocol = NodeInfoRepository()) {
        self.nodeInfoRepository = nodeInfoRepository
    }
    
    func node(fromHandle: MEGAHandle) -> MEGANode? {
        nodeInfoRepository.node(fromHandle: fromHandle)
    }
    
    func folderAuthNode(fromHandle: MEGAHandle) -> MEGANode? {
        nodeInfoRepository.folderNode(fromHandle: fromHandle)
    }
    
    func path(fromHandle: MEGAHandle) -> URL? {
        nodeInfoRepository.path(fromHandle: fromHandle)
    }
    
    func childrenInfo(fromParentHandle: MEGAHandle) -> [AudioPlayerItem]? {
        nodeInfoRepository.childrenInfo(fromParentHandle: fromParentHandle)
    }
    
    func folderChildrenInfo(fromParentHandle: MEGAHandle) -> [AudioPlayerItem]? {
        nodeInfoRepository.folderChildrenInfo(fromParentHandle: fromParentHandle)
    }
    
    func info(fromNode: MEGANode) -> AudioPlayerItem? {
        nodeInfoRepository.info(fromNodes: [fromNode])?.first
    }
    
    func publicNode(fromFileLink: String, completion: @escaping ((MEGANode?) -> Void)) {
        nodeInfoRepository.publicNode(fromFileLink: fromFileLink, completion: completion)
    }
    
    func loginToFolder(link: String) {
        nodeInfoRepository.loginToFolder(link: link)
    }
    
    func folderLinkLogout() {
        nodeInfoRepository.folderLinkLogout()
    }
}
