@testable import MEGA
import MEGAAppSDKRepoMock
import MEGADomain

final class MockStreamingInfoUseCase: StreamingInfoUseCaseProtocol, @unchecked Sendable {
    private(set) var startServer_calledTimes = 0
    private(set) var stopServer_calledTimes = 0
    
    private var infoNode: MockNode?
    private var infoNodePlayerItem: AudioPlayerItem?
    
    func startServer() {
        startServer_calledTimes += 1
    }
    
    func stopServer() {
        stopServer_calledTimes += 1
    }
    
    func info(from folderLinkNode: MEGANode) -> MEGA.AudioPlayerItem? {
        infoNodePlayerItem
    }

    func isLocalHTTPProxyServerRunning() -> Bool {
        false
    }
    
    func completeInfoNode(with audioPlayerItem: AudioPlayerItem) {
        infoNodePlayerItem = audioPlayerItem
    }
    
    func completeInfoNode(with node: MockNode) {
        infoNode = node
    }
    
    func path(fromNode: MEGANode) -> URL? {
        nil
    }
    
}
