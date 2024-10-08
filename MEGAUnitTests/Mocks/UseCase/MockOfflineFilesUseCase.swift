@testable import MEGA
import MEGADomain

final class MockOfflineFilesUseCase: OfflineFilesUseCaseProtocol {
    private let offlineFile: OfflineFileEntity?
    
    init(offlineFile: OfflineFileEntity? = nil) {
        self.offlineFile = offlineFile
    }
    
    func offlineFile(for handle: String) -> OfflineFileEntity? {
        offlineFile
    }
    
    func offlineFiles() -> [OfflineFileEntity] {
        guard let offlineFile else { return [] }
        return [offlineFile]
    }
}
