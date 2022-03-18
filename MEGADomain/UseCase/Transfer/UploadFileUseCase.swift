// MARK: - Use case protocol -
protocol UploadFileUseCaseProtocol {
    func hasExistFile(name: String, parentHandle: MEGAHandle) -> Bool
    func uploadFile(withLocalPath path: String, toParent parent: MEGAHandle, completion: @escaping (Result<TransferEntity, TransferErrorEntity>) -> Void)
    func uploadSupportFile(atPath path: String, start: @escaping (TransferEntity) -> Void, progress: @escaping (TransferEntity) -> Void, completion: @escaping (Result<TransferEntity, TransferErrorEntity>) -> Void)
    func cancel(transfer: TransferEntity, completion: @escaping (Result<Void, TransferErrorEntity>) -> Void)
}

// MARK: - Use case implementation -
struct UploadFileUseCase: UploadFileUseCaseProtocol {
    private let repo: UploadFileRepositoryProtocol
    
    init(repo: UploadFileRepositoryProtocol) {
        self.repo = repo
    }
    
    func hasExistFile(name: String, parentHandle: MEGAHandle) -> Bool {
        repo.hasExistFile(name: name, parentHandle: parentHandle)
    }
    func uploadFile(withLocalPath path: String, toParent parent: MEGAHandle, completion: @escaping (Result<TransferEntity, TransferErrorEntity>) -> Void) {
        repo.uploadFile(withLocalPath: path, toParent: parent, completion: completion)
    }
    func uploadSupportFile(atPath path: String, start: @escaping (TransferEntity) -> Void, progress: @escaping (TransferEntity) -> Void, completion: @escaping (Result<TransferEntity, TransferErrorEntity>) -> Void) {
        repo.uploadSupportFile(atPath: path, start: start, progress: progress, completion: completion)
    }
    func cancel(transfer: TransferEntity, completion: @escaping (Result<Void, TransferErrorEntity>) -> Void) {
        repo.cancel(transfer: transfer, completion: completion)
    }
}
