@testable import MEGA

class MockOfflineInfoRepository: OfflineInfoRepositoryProtocol, @unchecked Sendable {
    var result: Result<Void, NodeInfoError>
    
    private(set) var localPathfromNodeCallCount = 0
    private let isOffline: Bool
    
    init(result: Result<Void, NodeInfoError> = .success, isOffline: Bool = false) {
        self.result = result
        self.isOffline = isOffline
    }
    
    func info(fromFiles: [String]?) -> [AudioPlayerItem]? {
        switch result {
        case .failure: return nil
        case .success: return AudioPlayerItem.mockArray
        }
    }
    
    func localPath(fromNode: MEGANode) -> URL? {
        localPathfromNodeCallCount += 1
        switch result {
        case .failure: return nil
        case .success: return AudioPlayerItem.mockItem.url
        }
    }
    
    func isOffline(node: MEGANode) -> Bool {
        isOffline
    }
}
