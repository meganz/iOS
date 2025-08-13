@testable import MEGA
import MEGADomain

enum NodeInfoError: Error {
    case generic
}

struct MockNodeInfoRepository: NodeInfoRepositoryProtocol {
    
    var result: Result<Void, NodeInfoError>
    var violatesTermsOfServiceResult: Result<Bool, NodeInfoError>
    
    init(
        result: Result<Void, NodeInfoError> = .success,
        violatesTermsOfServiceResult: Result<Bool, NodeInfoError> = .success(false)
    ) {
        self.result = result
        self.violatesTermsOfServiceResult = violatesTermsOfServiceResult
    }
    
    func path(fromHandle: HandleEntity) -> URL? {
        switch result {
        case .failure: return nil
        case .success: return URL(string: "www.mega.app")
        }
    }
    
    func info(fromNodes: [MEGANode]?) -> [AudioPlayerItem]? {
        switch result {
        case .failure: return nil
        case .success: return AudioPlayerItem.mockArray
        }
    }
    
    func authInfo(fromNodes: [MEGANode]?) -> [AudioPlayerItem]? {
        switch result {
        case .failure: return nil
        case .success: return AudioPlayerItem.mockArray
        }
    }
    
    func childrenInfo(fromParentHandle: HandleEntity) -> [AudioPlayerItem]? {
        switch result {
        case .failure: return nil
        case .success: return AudioPlayerItem.mockArray
        }
    }
    
    func folderChildrenInfo(fromParentHandle: HandleEntity) -> [AudioPlayerItem]? {
        switch result {
        case .failure: return nil
        case .success: return AudioPlayerItem.mockArray
        }
    }
    
    func node(fromHandle: HandleEntity) -> MEGANode? {
        switch result {
        case .failure: return nil
        case .success: return MEGANode()
        }
    }
    
    func folderNode(fromHandle: HandleEntity) -> MEGANode? {
        switch result {
        case .failure: return nil
        case .success: return MEGANode()
        }
    }
    
    func folderAuthNode(fromNode: MEGANode) -> MEGANode? {
        switch result {
        case .failure: return nil
        case .success: return MEGANode()
        }
    }
    
    func folderLinkLogout() {}
    
    func isFolderLinkNodeTakenDown(node: MEGANode) async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
            continuation.resume(with: violatesTermsOfServiceResult)
        }
    }
    
    func isNodeTakenDown(node: MEGANode) async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
            continuation.resume(with: violatesTermsOfServiceResult)
        }
    }
}
