import Foundation
import MEGADomain

public final class MockOfflineFilesRepository: OfflineFilesRepositoryProtocol, @unchecked Sendable {
    public static let newRepo = MockOfflineFilesRepository()
    
    private let offlineFileEntities: [OfflineFileEntity]
    private let offlineFileEntity: OfflineFileEntity?
    
    public var removeAllOfflineNodesCalledTimes = 0
    
    public init(
        offlineFileEntities: [OfflineFileEntity] = [],
        offlineFileEntity: OfflineFileEntity? = nil
    ) {
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
    
    public func createOfflineFile(name: String, for handle: HandleEntity) {}
    
    public func removeAllStoredOfflineNodes() {
        removeAllOfflineNodesCalledTimes += 1
    }
}
