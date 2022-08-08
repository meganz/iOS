@testable import MEGA
import MEGADomain

enum NodeInfoError: Error {
    case generic
}

struct MockNodeInfoRepository: NodeInfoRepositoryProtocol {
    
    var result: Result<Void, NodeInfoError>
    
    init(result: Result<Void, NodeInfoError> = .success(())) {
        self.result = result
    }
    
    func path(fromHandle: HandleEntity) -> URL? {
        switch result {
        case .failure: return nil
        case .success: return URL(string: "www.mega.nz")
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
    
    func publicNode(fromFileLink: String, completion: @escaping ((MEGANode?) -> Void)) {
        switch result {
        case .failure: return completion(nil)
        case .success: return completion(MEGANode())
        }
    }
    
    func loginToFolder(link: String) {}
    func folderLinkLogout() {}
}
