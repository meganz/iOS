@testable import MEGA

struct MockOfflineInfoRepository: OfflineInfoRepositoryProtocol {
    var result: Result<Void, NodeInfoError>
    
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
        switch result {
        case .failure: return nil
        case .success: return AudioPlayerItem.mockItem.url
        }
    }
}
