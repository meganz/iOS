import Foundation
import MEGADomain

protocol NodeInfoUseCaseProtocol {
    func node(fromHandle: HandleEntity) -> MEGANode?
    func folderAuthNode(fromHandle: HandleEntity) -> MEGANode?
    func path(fromHandle: HandleEntity) -> URL?
    func childrenInfo(fromParentHandle: HandleEntity) -> [AudioPlayerItem]?
    func folderChildrenInfo(fromParentHandle: HandleEntity) -> [AudioPlayerItem]?
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
    
    func node(fromHandle: HandleEntity) -> MEGANode? {
        nodeInfoRepository.node(fromHandle: fromHandle)
    }
    
    func folderAuthNode(fromHandle: HandleEntity) -> MEGANode? {
        nodeInfoRepository.folderNode(fromHandle: fromHandle)
    }
    
    func path(fromHandle: HandleEntity) -> URL? {
        nodeInfoRepository.path(fromHandle: fromHandle)
    }
    
    func childrenInfo(fromParentHandle: HandleEntity) -> [AudioPlayerItem]? {
        nodeInfoRepository.childrenInfo(fromParentHandle: fromParentHandle)
    }
    
    func folderChildrenInfo(fromParentHandle: HandleEntity) -> [AudioPlayerItem]? {
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
