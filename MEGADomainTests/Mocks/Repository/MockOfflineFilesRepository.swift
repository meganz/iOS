@testable import MEGA
import MEGADomain

struct MockOfflineFilesRepository: OfflineFilesRepositoryProtocol {
    static let newRepo = MockOfflineFilesRepository()
    
    var offlineURL: URL?
    var offlineFilesMock: [OfflineFileEntity] = []
    var offlineFileMock: OfflineFileEntity?
    
    func offlineFiles() -> [OfflineFileEntity] {
        offlineFilesMock
    }
    
    func offlineFile(for base64Handle: String) -> OfflineFileEntity? {
        offlineFileMock
    }
    
    func createOfflineFile(name: String, for handle: HandleEntity) {    }
}
