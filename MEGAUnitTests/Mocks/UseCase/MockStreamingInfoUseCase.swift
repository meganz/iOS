@testable import MEGA
import MEGAAppSDKRepoMock
import MEGADomain

final class MockStreamingInfoUseCase: StreamingInfoUseCaseProtocol, @unchecked Sendable {    
    private(set) var startServer_calledTimes = 0
    private(set) var stopServer_calledTimes = 0
    
    private var infoNode: MockNode?
    private var infoNodeTrack: TrackEntity?
    
    func startServer() {
        startServer_calledTimes += 1
    }
    
    func stopServer() {
        stopServer_calledTimes += 1
    }
    
    func fetchTrack(from folderLinkNode: MEGANode) -> TrackEntity? {
        infoNodeTrack
    }

    func isLocalHTTPServerRunning() -> Bool {
        false
    }
    
    func completeInfoNode(with track: TrackEntity) {
        infoNodeTrack = track
    }
    
    func completeInfoNode(with node: MockNode) {
        infoNode = node
    }
    
    func streamingURL(for node: MEGANode) -> URL? {
        nil
    }
}
