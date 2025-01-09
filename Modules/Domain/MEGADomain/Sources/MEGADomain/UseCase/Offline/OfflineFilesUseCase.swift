import Foundation

// MARK: - Use case protocol -
public protocol OfflineFilesUseCaseProtocol {
    func offlineFiles() -> [OfflineFileEntity]
    func offlineFile(for base64Handle: String) -> OfflineFileEntity?
}

// MARK: - Use case implementation -
public struct OfflineFilesUseCase: OfflineFilesUseCaseProtocol {
    private let repo: any OfflineFileFetcherRepositoryProtocol
    
    public init(repo: some OfflineFileFetcherRepositoryProtocol) {
        self.repo = repo
    }
    
    public func offlineFiles() -> [OfflineFileEntity] {
        repo.offlineFiles()
    }
    
    public func offlineFile(for base64Handle: String) -> OfflineFileEntity? {
        repo.offlineFile(for: base64Handle)
    }
}
