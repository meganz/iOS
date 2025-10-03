@testable import MEGA
import MEGADomain

final class MockStreamingInfoRepository: StreamingInfoRepositoryProtocol, @unchecked Sendable {
    var result: Result<Void, NodeInfoError>
    private(set) var pathFromNodeCallCount = 0
    private(set) var serverStartCallCount = 0
    private(set) var serverStopCallCount = 0
    
    private var isRunning: Bool
    
    init(
        result: Result<Void, NodeInfoError> = .success,
        isRunning: Bool = false
    ) {
        self.result = result
        self.isRunning = isRunning
    }
    
    func serverStart() {
        serverStartCallCount += 1
        isRunning = true
    }
    
    func serverStop() {
        serverStopCallCount += 1
        isRunning = false
    }
    
    func fetchTrack(from node: MEGANode) -> AudioPlayerItem? {
        guard case .success = result else { return nil }
        return .mockItem
    }
    
    func streamingURL(for node: MEGANode) -> URL? {
        pathFromNodeCallCount += 1
        guard case .success = result else { return nil }
        return AudioPlayerItem.mockItem.url
    }
    
    func isLocalHTTPServerRunning() -> Bool {
        isRunning
    }
}
