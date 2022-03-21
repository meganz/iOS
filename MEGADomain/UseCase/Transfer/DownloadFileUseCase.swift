// MARK: - Use case protocol -
protocol DownloadFileUseCaseProtocol {
    func download(nodeHandle: MEGAHandle, to path: String, appData: String?, completion: @escaping (Result<TransferEntity, TransferErrorEntity>) -> Void)
    func downloadToTempFolder(nodeHandle: MEGAHandle, appData: String?, progress: ((TransferEntity) -> Void)?, completion: @escaping (Result<TransferEntity, TransferErrorEntity>) -> Void)
    func downloadTo(folderPath: String, nodeHandle: MEGAHandle, appData: String?, progress: ((TransferEntity) -> Void)?, completion: @escaping (Result<TransferEntity, TransferErrorEntity>) -> Void)
}

// MARK: - Use case implementation -
struct DownloadFileUseCase<T: DownloadFileRepositoryProtocol>: DownloadFileUseCaseProtocol {
    private let repo: T
    
    init(repo: T) {
        self.repo = repo
    }
    
    func download(nodeHandle: MEGAHandle, to path: String, appData: String?, completion: @escaping (Result<TransferEntity, TransferErrorEntity>) -> Void) {
        repo.download(nodeHandle: nodeHandle, to: path, appData: appData, completion: completion)
    }
    
    func downloadToTempFolder(nodeHandle: MEGAHandle, appData: String?, progress: ((TransferEntity) -> Void)?, completion: @escaping (Result<TransferEntity, TransferErrorEntity>) -> Void) {
        repo.downloadToTempFolder(nodeHandle: nodeHandle, appData: appData, progress: progress, completion: completion)
    }
    
    func downloadTo(folderPath: String, nodeHandle: MEGAHandle, appData: String?, progress: ((TransferEntity) -> Void)?, completion: @escaping (Result<TransferEntity, TransferErrorEntity>) -> Void) {
        repo.downloadTo(folderPath: folderPath, nodeHandle: nodeHandle, appData: appData, progress: progress, completion: completion)
    }
}
