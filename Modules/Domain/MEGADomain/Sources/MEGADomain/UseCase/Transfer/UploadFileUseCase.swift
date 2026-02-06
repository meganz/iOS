import Foundation
import MEGASwift

public enum FileUploadEvent: Sendable {
    case start(TransferEntity)
    case progress(TransferEntity)
    case completion(TransferEntity)
}

// MARK: - Use case protocol -
public protocol UploadFileUseCaseProtocol: Sendable {
    func hasExistFile(name: String, parentHandle: HandleEntity) -> Bool
    func uploadFile(_ url: URL, toParent parent: HandleEntity, fileName: String?, appData: String?, isSourceTemporary: Bool, startFirst: Bool, start: ((TransferEntity) -> Void)?, update: ((TransferEntity) -> Void)?, completion: ((Result<Void, TransferErrorEntity>) -> Void)?)
    /// Uploads a file from a specified URL to a parent folder.
    ///
    /// - Parameters:
    ///   - url: The URL of the file to upload.
    ///   - parent: The handle of the parent folder.
    ///   - uploadOptions: the uploadOptions
    ///   - start: An optional closure called when the upload starts.
    ///   - progress: An optional closure called to update the progress of the upload.
    ///   - completion: An optional closure called upon completion of the upload.
    func uploadFile(
        _ url: URL,
        toParent parent: HandleEntity,
        uploadOptions: UploadOptionsEntity,
        start: ((TransferEntity) -> Void)?,
        progress: ((TransferEntity) -> Void)?,
        completion: ((Result<TransferEntity, TransferErrorEntity>) -> Void)?
    )
    
    /// Uploads a file from a specified URL to a parent folder asynchronously.
    ///
    /// - Parameters:
    ///   - url: The URL of the file to upload.
    ///   - parent: The node entity representing the parent folder.
    ///   - uploadOptions: Configuration options for the upload, including file name, app data, source handling, and priority settings.
    ///   - start: An optional closure called when the upload starts, providing the transfer entity.
    ///   - progress: An optional closure called periodically to report upload progress, providing the updated transfer entity.
    /// - Returns: The transfer entity representing the completed upload.
    /// - Throws: A `TransferErrorEntity` if the upload fails.
    func uploadFile(
        _ url: URL,
        toParent parent: HandleEntity,
        uploadOptions: UploadOptionsEntity,
        start: ((TransferEntity) -> Void)?,
        progress: ((TransferEntity) -> Void)?
    ) async throws -> TransferEntity
    func uploadSupportFile(_ url: URL) async throws -> AnyAsyncSequence<FileUploadEvent>
    func cancel(transfer: TransferEntity) async throws
    func tempURL(forFilename filename: String) -> URL
    func nodeForHandle(_ handle: HandleEntity) -> NodeEntity?
    func cancelUploadTransfers()
}

// MARK: - Use case implementation -
public struct UploadFileUseCase<T: UploadFileRepositoryProtocol, U: FileSystemRepositoryProtocol, V: NodeRepositoryProtocol, W: FileCacheRepositoryProtocol>: UploadFileUseCaseProtocol {
    private let uploadFileRepository: T
    private let fileSystemRepository: U
    private let nodeRepository: V
    private let fileCacheRepository: W

    public init(uploadFileRepository: T, fileSystemRepository: U, nodeRepository: V, fileCacheRepository: W) {
        self.uploadFileRepository = uploadFileRepository
        self.fileSystemRepository = fileSystemRepository
        self.nodeRepository = nodeRepository
        self.fileCacheRepository = fileCacheRepository
    }
    
    public func nodeForHandle(_ handle: HandleEntity) -> NodeEntity? {
        nodeRepository.nodeForHandle(handle)
    }
    
    public func hasExistFile(name: String, parentHandle: HandleEntity) -> Bool {
        uploadFileRepository.hasExistFile(name: name, parentHandle: parentHandle)
    }
    
    public func uploadFile(_ url: URL, toParent parent: HandleEntity, fileName: String?, appData: String?, isSourceTemporary: Bool, startFirst: Bool, start: ((TransferEntity) -> Void)?, update: ((TransferEntity) -> Void)?, completion: ((Result<Void, TransferErrorEntity>) -> Void)?) {
        
        let name = fileName ?? url.lastPathComponent
        let uploadUrl = fileCacheRepository.tempUploadURL(for: name)
        
        guard fileSystemRepository.moveFile(at: url, to: uploadUrl) else {
            completion?(.failure(.moveFileToUploadsFolderFailed))
            return
        }
        
        uploadFileRepository.uploadFile(uploadUrl, toParent: parent, fileName: fileName, appData: appData, isSourceTemporary: isSourceTemporary, startFirst: startFirst, start: start, update: update) { result in
            switch result {
            case .success:
                completion?(.success)
            case .failure(let error):
                completion?(.failure(error))
            }
            try? fileSystemRepository.removeItem(at: uploadUrl)
        }
    }
    
    public func uploadFile(
        _ url: URL,
        toParent parent: HandleEntity,
        uploadOptions: UploadOptionsEntity,
        start: ((TransferEntity) -> Void)?,
        progress: ((TransferEntity) -> Void)?,
        completion: ((Result<TransferEntity, TransferErrorEntity>) -> Void)?
    ) {
        let name = uploadOptions.fileName ?? url.lastPathComponent
        let uploadUrl = fileCacheRepository.tempUploadURL(for: name)
        
        guard fileSystemRepository.moveFile(at: url, to: uploadUrl) else {
            completion?(.failure(.moveFileToUploadsFolderFailed))
            return
        }
        
        uploadFileRepository.uploadFile(uploadUrl, toParent: parent, uploadOptions: uploadOptions, start: start, progress: progress) { result in
            switch result {
            case .success(let transferEntity):
                completion?(.success(transferEntity))
            case .failure(let error):
                completion?(.failure(error))
            }
            try? fileSystemRepository.removeItem(at: uploadUrl)
        }
    }
    
    public func uploadFile(
        _ url: URL,
        toParent parent: HandleEntity,
        uploadOptions: UploadOptionsEntity,
        start: ((TransferEntity) -> Void)?,
        progress: ((TransferEntity) -> Void)?
    ) async throws -> TransferEntity {
        let name = uploadOptions.fileName ?? url.lastPathComponent
        let uploadUrl = fileCacheRepository.tempUploadURL(for: name)
        
        guard fileSystemRepository.moveFile(at: url, to: uploadUrl) else {
            throw TransferErrorEntity.moveFileToUploadsFolderFailed
        }
        
        let transfer = try await uploadFileRepository.uploadFile(uploadUrl, toParent: parent, uploadOptions: uploadOptions, start: start, progress: progress)
        return transfer
    }
    
    public func uploadSupportFile(_ url: URL) async throws -> AnyAsyncSequence<FileUploadEvent> {
        try await uploadFileRepository.uploadSupportFile(url)
    }
    
    public func cancel(transfer: TransferEntity) async throws {
        try await uploadFileRepository.cancel(transfer: transfer)
    }
    
    public func tempURL(forFilename filename: String) -> URL {
        fileCacheRepository.tempFolder.appendingPathComponent(filename)
    }
    
    public func cancelUploadTransfers() {
        uploadFileRepository.cancelUploadTransfers()
    }
}
