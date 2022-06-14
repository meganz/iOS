// MARK: - Use case protocol -
protocol UploadFileUseCaseProtocol {
    func hasExistFile(name: String, parentHandle: MEGAHandle) -> Bool
    func uploadFile(withLocalPath path: String, toParent parent: MEGAHandle, fileName: String?, appData: String?, isSourceTemporary: Bool, startFirst: Bool, cancelToken: MEGACancelToken, start: ((TransferEntity) -> Void)?, update: ((TransferEntity) -> Void)?, completion: ((Result<Void, TransferErrorEntity>) -> Void)?)
    func uploadSupportFile(atPath path: String, start: @escaping (TransferEntity) -> Void, progress: @escaping (TransferEntity) -> Void, completion: @escaping (Result<TransferEntity, TransferErrorEntity>) -> Void)
    func cancel(transfer: TransferEntity, completion: @escaping (Result<Void, TransferErrorEntity>) -> Void)
}

// MARK: - Use case implementation -
struct UploadFileUseCase<T: UploadFileRepositoryProtocol, U: FileSystemRepositoryProtocol, V: NodeRepositoryProtocol, W: FileCacheRepositoryProtocol>: UploadFileUseCaseProtocol {
    private let uploadFileRepository: T
    private let fileSystemRepository: U
    private let nodeRepository: V
    private let fileCacheRepository: W

    init(uploadFileRepository: T, fileSystemRepository: U, nodeRepository: V, fileCacheRepository: W) {
        self.uploadFileRepository = uploadFileRepository
        self.fileSystemRepository = fileSystemRepository
        self.nodeRepository = nodeRepository
        self.fileCacheRepository = fileCacheRepository
    }
    
    func hasExistFile(name: String, parentHandle: MEGAHandle) -> Bool {
        uploadFileRepository.hasExistFile(name: name, parentHandle: parentHandle)
    }
    
    func uploadFile(withLocalPath path: String, toParent parent: MEGAHandle, fileName: String?, appData: String?, isSourceTemporary: Bool, startFirst: Bool, cancelToken: MEGACancelToken, start: ((TransferEntity) -> Void)?, update: ((TransferEntity) -> Void)?, completion: ((Result<Void, TransferErrorEntity>) -> Void)?) {
        
        let originalUrl = URL(fileURLWithPath: path)
        let name = fileName ?? originalUrl.lastPathComponent
        let uploadUrl = fileCacheRepository.tempUploadURL(for: name)
        
        guard fileSystemRepository.moveFile(at: originalUrl, to: uploadUrl, name: name) else {
            completion?(.failure(.moveFileToUploadsFolderFailed))
            return
        }
        
        guard nodeRepository.copyNodeIfExistsWithSameFingerprint(at: uploadUrl.path, parentHandle: parent) else {
            uploadFileRepository.uploadFile(withLocalPath: uploadUrl.path, toParent: parent, fileName: fileName, appData: appData, isSourceTemporary: isSourceTemporary, startFirst: startFirst, cancelToken: cancelToken, start: start, update: update) { result in
                switch result {
                case .success(_):
                    completion?(.success)
                case .failure(let error):
                    completion?(.failure(error))
                }
                fileSystemRepository.removeFile(at: uploadUrl)
            }
            return
        }
        
        fileSystemRepository.removeFile(at: uploadUrl)
        completion?(.success)
    }
    
    func uploadSupportFile(atPath path: String, start: @escaping (TransferEntity) -> Void, progress: @escaping (TransferEntity) -> Void, completion: @escaping (Result<TransferEntity, TransferErrorEntity>) -> Void) {
        uploadFileRepository.uploadSupportFile(atPath: path, start: start, progress: progress, completion: completion)
    }
    
    func cancel(transfer: TransferEntity, completion: @escaping (Result<Void, TransferErrorEntity>) -> Void) {
        uploadFileRepository.cancel(transfer: transfer, completion: completion)
    }
}
