import MEGADomain
import Foundation

public struct MockOfflineFilesRepository: OfflineFilesRepositoryProtocol {
    public static let newRepo = MockOfflineFilesRepository()
    
    private let offlineFileEntities: [OfflineFileEntity]
    private let offlineFileEntity: OfflineFileEntity?
    
    public init(offlineFileEntities: [OfflineFileEntity] = [],
                offlineFileEntity: OfflineFileEntity? = nil) {
        self.offlineFileEntities = offlineFileEntities
        self.offlineFileEntity = offlineFileEntity
    }
    
    public var offlineURL: URL? = URL(fileURLWithPath: "Documents")
    
    public func offlineFiles() -> [OfflineFileEntity] {
        offlineFileEntities
    }
    
    public func offlineFile(for base64Handle: String) -> OfflineFileEntity? {
        offlineFileEntity
    }
    
    public func createOfflineFile(name: String, for handle: HandleEntity) {    }
}
