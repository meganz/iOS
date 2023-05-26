import Foundation

// MARK: - Use case protocol -
public protocol OfflineFilesUseCaseProtocol {
    func offlineFiles() -> [OfflineFileEntity]
    func offlineFile(for base64Handle: String) -> OfflineFileEntity?
}

// MARK: - Use case implementation -
public struct OfflineFilesUseCase<T: OfflineFileFetcherRepositoryProtocol>: OfflineFilesUseCaseProtocol {

    private let repo: T

    public init(repo: T) {
        self.repo = repo
    }
    
    public func offlineFiles() -> [OfflineFileEntity] {
        return repo.offlineFiles()
    }
    
    public func offlineFile(for base64Handle: String) -> OfflineFileEntity? {
        return repo.offlineFile(for: base64Handle)
    }
}
