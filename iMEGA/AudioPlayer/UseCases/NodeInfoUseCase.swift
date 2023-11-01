import Foundation
import MEGADomain

protocol NodeInfoUseCaseProtocol {
    func node(fromHandle: HandleEntity) -> MEGANode?
    func childrenInfo(fromParentHandle: HandleEntity) -> [AudioPlayerItem]?
    func folderChildrenInfo(fromParentHandle: HandleEntity) -> [AudioPlayerItem]?
    func folderLinkLogout()
}

final class NodeInfoUseCase: NodeInfoUseCaseProtocol {
    private var nodeInfoRepository: any NodeInfoRepositoryProtocol
    
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
}
