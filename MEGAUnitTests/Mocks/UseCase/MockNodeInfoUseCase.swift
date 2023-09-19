@testable import MEGA
import MEGADomain

final class MockNodeInfoUseCase: NodeInfoUseCaseProtocol {
    
    private(set) var folderLinkLogout_callTimes = 0
    
    func node(fromHandle: MEGADomain.HandleEntity) -> MEGANode? {
        nil
    }
    
    func folderAuthNode(fromHandle: MEGADomain.HandleEntity) -> MEGANode? {
        nil
    }
    
    func path(fromHandle: MEGADomain.HandleEntity) -> URL? {
        nil
    }
    
    func childrenInfo(fromParentHandle: MEGADomain.HandleEntity) -> [MEGA.AudioPlayerItem]? {
        nil
    }
    
    func folderChildrenInfo(fromParentHandle: MEGADomain.HandleEntity) -> [MEGA.AudioPlayerItem]? {
        nil
    }
    
    func info(fromNode: MEGANode) -> MEGA.AudioPlayerItem? {
        nil
    }
    
    func publicNode(fromFileLink: String) async -> MEGANode? {
        nil
    }
    
    func loginToFolder(link: String) {
        
    }
    
    func folderLinkLogout() {
        folderLinkLogout_callTimes += 1
    }
}
