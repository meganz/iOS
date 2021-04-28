protocol UploadFileRepositoryProtocol {
    func hasExistFile(name: String, parentHandle: MEGAHandle) -> Bool
    func uploadFile(withLocalPath path: String, toParent parent: MEGAHandle, completion: @escaping (Result<TransferEntity, TransferErrorEntity>) -> Void)
}
