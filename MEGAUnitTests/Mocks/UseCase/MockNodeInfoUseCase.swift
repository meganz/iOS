@testable import MEGA
import MEGADomain

final class MockNodeInfoUseCase: NodeInfoUseCaseProtocol, @unchecked Sendable {
    private var isTakenDownNode: Bool
    private(set) var folderLinkLogout_callTimes = 0
    
    init(isTakenDownNode: Bool = false) {
        self.isTakenDownNode = isTakenDownNode
    }
    
    func node(for: HandleEntity) -> MEGANode? {
        nil
    }
    
    func fetchAudioTracks(from folder: HandleEntity) -> [AudioPlayerItem]? {
        nil
    }
    
    func fetchFolderLinkAudioTracks(from folder: HandleEntity) -> [AudioPlayerItem]? {
        nil
    }
    
    func folderLinkLogout() {
        folderLinkLogout_callTimes += 1
    }
    
    func isTakenDown(node: MEGANode, isFolderLink: Bool) async throws -> Bool {
        isTakenDownNode
    }
}
