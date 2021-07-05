// MARK: - Use case protocol -
protocol DownloadFileUseCaseProtocol {
    func downloadToTempFolder(nodeHandle: MEGAHandle, progress: @escaping (TransferEntity) -> Void, completion: @escaping (Result<TransferEntity, TransferErrorEntity>) -> Void)
}

// MARK: - Use case implementation -
struct DownloadFileUseCase: DownloadFileUseCaseProtocol {
    private let repo: DownloadFileRepositoryProtocol
    
    init(repo: DownloadFileRepositoryProtocol) {
        self.repo = repo
    }
    
    func downloadToTempFolder(nodeHandle: MEGAHandle, progress: @escaping (TransferEntity) -> Void, completion: @escaping (Result<TransferEntity, TransferErrorEntity>) -> Void) {
        repo.downloadToTempFolder(nodeHandle: nodeHandle, progress: progress, completion: completion)
    }
}
