@testable import MEGA

struct MockOfflineFilesRepository: OfflineFilesRepositoryProtocol {
    var relativeOfflinePath: String = "Documents/"
    var offlineFilesMock: [OfflineFileEntity] = []
    var offlineFileMock: OfflineFileEntity?
    
    func offlineFiles() -> [OfflineFileEntity] {
        offlineFilesMock
    }
    
    func offlineFile(for base64Handle: String) -> OfflineFileEntity? {
        offlineFileMock
    }
    
    func createOfflineFile(name: String, for handle: MEGAHandle) {    }
}
