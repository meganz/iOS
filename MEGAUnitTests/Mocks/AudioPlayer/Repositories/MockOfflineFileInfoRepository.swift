@testable import MEGA

class MockOfflineInfoRepository: OfflineInfoRepositoryProtocol, @unchecked Sendable {
    var result: Result<Void, NodeInfoError>
    
    private(set) var localPathfromNodeCallCount = 0
    private let isOffline: Bool
    
    init(result: Result<Void, NodeInfoError> = .success, isOffline: Bool = false) {
        self.result = result
        self.isOffline = isOffline
    }
    
    func fetchTracks(from files: [String]?) -> [AudioPlayerItem]? {
        switch result {
        case .failure: return nil
        case .success: return AudioPlayerItem.mockArray
        }
    }
    
    func offlineFileURL(for node: MEGANode) -> URL? {
        localPathfromNodeCallCount += 1
        switch result {
        case .failure: return nil
        case .success: return AudioPlayerItem.mockItem.url
        }
    }
    
    func isNodeAvailableOffline(_ node: MEGANode) -> Bool {
        isOffline
    }
}
