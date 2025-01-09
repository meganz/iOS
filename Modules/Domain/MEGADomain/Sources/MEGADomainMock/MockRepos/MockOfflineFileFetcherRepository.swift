import MEGADomain

public struct MockOfflineFileFetcherRepository: OfflineFileFetcherRepositoryProtocol {
    public static let newRepo = MockOfflineFileFetcherRepository()
    
    private let offlineFileEntities: [OfflineFileEntity]
    private let offlineFileEntity: OfflineFileEntity?
    
    public init(offlineFileEntities: [OfflineFileEntity] = [],
                offlineFileEntity: OfflineFileEntity? = nil) {
        self.offlineFileEntities = offlineFileEntities
        self.offlineFileEntity = offlineFileEntity
    }
    
    public func offlineFiles() -> [OfflineFileEntity] {
        offlineFileEntities
    }
    
    public func offlineFile(for base64Handle: String) -> OfflineFileEntity? {
        offlineFileEntity
    }
    
    public func removeAllOfflineNodes() {}
}
