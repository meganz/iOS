import Foundation
import MEGADomain

public final class MockOfflineFilesRepository: OfflineFilesRepositoryProtocol, @unchecked Sendable {
    public static let newRepo = MockOfflineFilesRepository()
    
    private let offlineFileEntities: [OfflineFileEntity]
    private let offlineFileEntity: OfflineFileEntity?
    private let _offlineSize: UInt64
    
    public var removeAllOfflineNodesCalledTimes = 0
    
    public init(
        offlineFileEntities: [OfflineFileEntity] = [],
        offlineFileEntity: OfflineFileEntity? = nil,
        offlineSize: UInt64 = 0
    ) {
        self.offlineFileEntities = offlineFileEntities
        self.offlineFileEntity = offlineFileEntity
        _offlineSize = offlineSize
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
    
    public func offlineSize() -> UInt64 {
        _offlineSize
    }
}
