protocol DownloadFileRepositoryProtocol {
    func downloadToTempFolder(nodeHandle: MEGAHandle, progress: @escaping (TransferEntity) -> Void, completion: @escaping (Result<TransferEntity, TransferErrorEntity>) -> Void)
}
