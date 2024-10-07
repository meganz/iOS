@testable import MEGA

class MockOfflineInfoRepository: OfflineInfoRepositoryProtocol, @unchecked Sendable {
    var result: Result<Void, NodeInfoError>
    
    private(set) var localPathfromNodeCallCount = 0
    
    init(result: Result<Void, NodeInfoError> = .success(())) {
        self.result = result
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
}
