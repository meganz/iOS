import MEGADomain
import Foundation

// MARK: - Use case protocol -
protocol UploadFileUseCaseProtocol {
    func hasExistFile(name: String, parentHandle: HandleEntity) -> Bool
    func uploadFile(_ url: URL, toParent parent: HandleEntity, fileName: String?, appData: String?, isSourceTemporary: Bool, startFirst: Bool, cancelToken: MEGACancelToken?, start: ((TransferEntity) -> Void)?, update: ((TransferEntity) -> Void)?, completion: ((Result<Void, TransferErrorEntity>) -> Void)?)
    func uploadSupportFile(_ url: URL, start: @escaping (TransferEntity) -> Void, progress: @escaping (TransferEntity) -> Void, completion: @escaping (Result<TransferEntity, TransferErrorEntity>) -> Void)
    func cancel(transfer: TransferEntity, completion: @escaping (Result<Void, TransferErrorEntity>) -> Void)
    func tempURL(forFilename filename: String) -> URL
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
    
    func hasExistFile(name: String, parentHandle: HandleEntity) -> Bool {
        uploadFileRepository.hasExistFile(name: name, parentHandle: parentHandle)
    }
    
    func uploadFile(_ url: URL, toParent parent: HandleEntity, fileName: String?, appData: String?, isSourceTemporary: Bool, startFirst: Bool, cancelToken: MEGACancelToken?, start: ((TransferEntity) -> Void)?, update: ((TransferEntity) -> Void)?, completion: ((Result<Void, TransferErrorEntity>) -> Void)?) {
        
        let name = fileName ?? url.lastPathComponent
        let uploadUrl = fileCacheRepository.tempUploadURL(for: name)
        
        guard fileSystemRepository.moveFile(at: url, to: uploadUrl, name: name) else {
            completion?(.failure(.moveFileToUploadsFolderFailed))
            return
        }
        
        uploadFileRepository.uploadFile(uploadUrl, toParent: parent, fileName: fileName, appData: appData, isSourceTemporary: isSourceTemporary, startFirst: startFirst, cancelToken: cancelToken, start: start, update: update) { result in
            switch result {
            case .success:
                completion?(.success)
            case .failure(let error):
                completion?(.failure(error))
            }
            fileSystemRepository.removeFile(at: uploadUrl)
        }
    }
    
    func uploadSupportFile(_ url: URL, start: @escaping (TransferEntity) -> Void, progress: @escaping (TransferEntity) -> Void, completion: @escaping (Result<TransferEntity, TransferErrorEntity>) -> Void) {
        uploadFileRepository.uploadSupportFile(url, start: start, progress: progress, completion: completion)
    }
    
    func cancel(transfer: TransferEntity, completion: @escaping (Result<Void, TransferErrorEntity>) -> Void) {
        uploadFileRepository.cancel(transfer: transfer, completion: completion)
    }
    
    func tempURL(forFilename filename: String) -> URL {
        fileCacheRepository.tempFolder.appendingPathComponent(filename)
    }
}
