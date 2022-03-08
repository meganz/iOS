protocol DownloadFileRepositoryProtocol {
    func download(nodeHandle: MEGAHandle, to path: String, appData: String?, completion: @escaping (Result<TransferEntity, TransferErrorEntity>) -> Void)
    func downloadToTempFolder(nodeHandle: MEGAHandle, appData: String?, progress: ((TransferEntity) -> Void)?, completion: @escaping (Result<TransferEntity, TransferErrorEntity>) -> Void)
    func downloadTo(folderPath: String, nodeHandle: MEGAHandle, appData: String?, progress: ((TransferEntity) -> Void)?, completion: @escaping (Result<TransferEntity, TransferErrorEntity>) -> Void)
}
