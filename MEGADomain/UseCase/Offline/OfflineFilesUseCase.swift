import Foundation

// MARK: - Use case protocol -
protocol OfflineFilesUseCaseProtocol {
    func offlineFiles() -> [OfflineFileEntity]
    func offlineFile(for base64Handle: String) -> OfflineFileEntity?
}

// MARK: - Use case implementation -
struct OfflineFilesUseCase: OfflineFilesUseCaseProtocol {

    private let repo: OfflineFilesRepositoryProtocol

    init(repo: OfflineFilesRepositoryProtocol) {
        self.repo = repo
    }
    
    func offlineFiles() -> [OfflineFileEntity] {
        return repo.offlineFiles()
    }
    
    func offlineFile(for base64Handle: String) -> OfflineFileEntity? {
        return repo.offlineFile(for: base64Handle)
    }
}
