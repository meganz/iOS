@testable import MEGA
import MEGADomain

enum NodeInfoError: Error {
    case generic
}

final class MockNodeInfoRepository: NodeInfoRepositoryProtocol, @unchecked Sendable {
    var result: Result<Void, NodeInfoError>
    var violatesTermsOfServiceResult: Result<Bool, NodeInfoError>
    private(set) var folderLinkLogoutCount: Int = 0
    
    let defaultNode = MEGANode()
    
    init(
        result: Result<Void, NodeInfoError> = .success,
        violatesTermsOfServiceResult: Result<Bool, NodeInfoError> = .success(false)
    ) {
        self.result = result
        self.violatesTermsOfServiceResult = violatesTermsOfServiceResult
    }
    
    private var isSuccess: Bool {
        if case .success = result { return true }
        return false
    }
    
    func path(fromHandle: HandleEntity) -> URL? {
        isSuccess ? URL(string: "www.mega.app") : nil
    }
    
    func info(fromNodes: [MEGANode]?) -> [AudioPlayerItem]? {
        isSuccess ? AudioPlayerItem.mockArray : nil
    }
    
    func authInfo(fromNodes: [MEGANode]?) -> [AudioPlayerItem]? {
        isSuccess ? AudioPlayerItem.mockArray : nil
    }
    
    func fetchAudioTracks(from folder: HandleEntity) -> [AudioPlayerItem]? {
        isSuccess ? AudioPlayerItem.mockArray : nil
    }
    
    func fetchFolderLinkAudioTracks(from folder: HandleEntity) -> [AudioPlayerItem]? {
        isSuccess ? AudioPlayerItem.mockArray : nil
    }
    
    func node(for handle: HandleEntity) -> MEGANode? {
        isSuccess ? defaultNode : nil
    }
    
    func folderNode(fromHandle: HandleEntity) -> MEGANode? {
        isSuccess ? defaultNode : nil
    }
    
    func folderAuthNode(fromNode: MEGANode) -> MEGANode? {
        isSuccess ? defaultNode : nil
    }
    
    func folderLinkLogout() {
        folderLinkLogoutCount += 1
    }
    
    func isFolderLinkNodeTakenDown(node: MEGANode) async throws -> Bool {
        try violatesTermsOfServiceResult.get()
    }
    
    func isNodeTakenDown(node: MEGANode) async throws -> Bool {
        try violatesTermsOfServiceResult.get()
    }
}
