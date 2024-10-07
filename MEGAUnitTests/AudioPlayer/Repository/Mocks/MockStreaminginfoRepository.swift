@testable import MEGA
import MEGADomain

class MockStreamingInfoRepository: StreamingInfoRepositoryProtocol, @unchecked Sendable {
    var result: Result<Void, NodeInfoError>
    
    private(set) var pathFromNodeCallCount = 0
    
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
    
    func path(fromNode: MEGANode) -> URL? {
        pathFromNodeCallCount += 1
        switch result {
        case .failure: return nil
        case .success: return AudioPlayerItem.mockItem.url
        }
    }
    
    func isLocalHTTPProxyServerRunning() -> Bool { return false }
}
