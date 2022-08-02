@testable import MEGA

struct MockStreamingInfoRepository: StreamingInfoRepositoryProtocol {
    var result: Result<Void, NodeInfoError>
    
    init(result: Result<Void, NodeInfoError> = .success(())) {
        self.result = result
    }
    
    func serverStart() {}
    
    func serverStop() {}
    
    func info(fromFolderLinkNode: MEGANode) -> AudioPlayerItem? {
        switch result {
        case .failure: return nil
        case .success: return AudioPlayerItem.mockItem
        }
    }
    
    func info(fromHandle: HandleEntity) -> MEGANode? {
        switch result {
        case .failure: return nil
        case .success: return MEGANode()
        }
    }
    
    func path(fromNode: MEGANode) -> URL? {
        switch result {
        case .failure: return nil
        case .success: return AudioPlayerItem.mockItem.url
        }
    }
    
    func isLocalHTTPProxyServerRunning() -> Bool { return false }
}
