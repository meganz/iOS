@testable import MEGA
import MEGADomain

final class MockNodeInfoUseCase: NodeInfoUseCaseProtocol, @unchecked Sendable {
    private var isTakenDownNode: Bool
    private(set) var folderLinkLogout_callTimes = 0
    
    init(isTakenDownNode: Bool = false) {
        self.isTakenDownNode = isTakenDownNode
    }
    
    func node(fromHandle: MEGADomain.HandleEntity) -> MEGANode? {
        nil
    }
    
    func childrenInfo(fromParentHandle: MEGADomain.HandleEntity) -> [MEGA.AudioPlayerItem]? {
        nil
    }
    
    func folderChildrenInfo(fromParentHandle: MEGADomain.HandleEntity) -> [MEGA.AudioPlayerItem]? {
        nil
    }
    
    func folderLinkLogout() {
        folderLinkLogout_callTimes += 1
    }
    
    func isTakenDown(node: MEGANode, isFolderLink: Bool) async throws -> Bool {
        isTakenDownNode
    }
}
