// MARK: - Use case protocol -
protocol UploadFileUseCaseProtocol {
    func hasExistFile(name: String, parentHandle: MEGAHandle) -> Bool
    func uploadFile(withLocalPath path: String, toParent parent: MEGAHandle, completion: @escaping (Result<TransferEntity, TransferErrorEntity>) -> Void)
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
}
