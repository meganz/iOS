@testable import MEGA
import MEGADomain

class MockStreamingInfoRepository: StreamingInfoRepositoryProtocol, @unchecked Sendable {
    var result: Result<Void, NodeInfoError>
    
    private(set) var pathFromNodeCallCount = 0
    
    init(result: Result<Void, NodeInfoError> = .success) {
        self.result = result
    }
    
    func serverStart() {}
    
    func serverStop() {}
    
    func fetchTrack(from node: MEGANode) -> AudioPlayerItem? {
        guard case .success = result else { return nil }
        return .mockItem
    }
    
    func streamingURL(for node: MEGANode) -> URL? {
        pathFromNodeCallCount += 1
        guard case .success = result else { return nil }
        return AudioPlayerItem.mockItem.url
    }
    
    func isLocalHTTPServerRunning() -> Bool { false }
}
