protocol DownloadFileRepositoryProtocol {
    func downloadFile(nodeHandle: MEGAHandle, progress: @escaping (TransferEntity) -> Void, completion: @escaping (Result<TransferEntity, TransferErrorEntity>) -> Void)
}
