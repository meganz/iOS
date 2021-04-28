// MARK: - Use case protocol -
protocol DownloadFileUseCaseProtocol {
    func DownloadFile(nodeHandle: MEGAHandle, progress: @escaping (TransferEntity) -> Void, completion: @escaping (Result<TransferEntity, TransferErrorEntity>) -> Void)
}

// MARK: - Use case implementation -
struct DownloadFileUseCase: DownloadFileUseCaseProtocol {
    private let repo: DownloadFileRepositoryProtocol
    
    init(repo: DownloadFileRepositoryProtocol) {
        self.repo = repo
    }
    
    func DownloadFile(nodeHandle: MEGAHandle, progress: @escaping (TransferEntity) -> Void, completion: @escaping (Result<TransferEntity, TransferErrorEntity>) -> Void) {
        repo.downloadFile(nodeHandle: nodeHandle, progress: progress, completion: completion)
    }
}
