import Foundation
import MEGADomain

public final class MockUploadFileUseCase: UploadFileUseCaseProtocol {
    private let duplicate: Bool
    public var newName: String?
    private let uploadFileResult: (Result<Void, TransferErrorEntity>)?
    private let uploadSupportFileResult: (Result<TransferEntity, TransferErrorEntity>)?
    private let cancelTransferResult: (Result<Void, TransferErrorEntity>)
    private let filename: String
    private let nodeEntity: NodeEntity?
    private let transferEntity: TransferEntity?
    
    public init(
        duplicate: Bool = true,
        newName: String? = nil,
        uploadFileResult: Result<Void, TransferErrorEntity>? = nil,
        uploadSupportFileResult: Result<TransferEntity, TransferErrorEntity>? = nil,
        cancelTransferResult: Result<Void, TransferErrorEntity> = .failure(.generic),
        filename: String = "",
        nodeEntity: NodeEntity? = nil,
        transfer: TransferEntity? = nil
    ) {
        self.duplicate = duplicate
        self.newName = newName
        self.uploadFileResult = uploadFileResult
        self.uploadSupportFileResult = uploadSupportFileResult
        self.cancelTransferResult = cancelTransferResult
        self.filename = filename
        self.nodeEntity = nodeEntity
        self.transferEntity = transfer
    }
    
    public func nodeForHandle(_ handle: HandleEntity) -> NodeEntity? {
        nodeEntity
    }
    
    public func hasExistFile(name: String, parentHandle: HandleEntity) -> Bool {
        newName = name
        return duplicate
    }
    
    public func uploadFile(_ url: URL, toParent parent: HandleEntity, fileName: String?, appData: String?, isSourceTemporary: Bool, startFirst: Bool, start: ((TransferEntity) -> Void)?, update: ((TransferEntity) -> Void)?, completion: ((Result<Void, TransferErrorEntity>) -> Void)?) {
        guard let result = uploadFileResult else { return }
        completion?(result)
    }
    
    public func uploadSupportFile(_ url: URL, start: @escaping (TransferEntity) -> Void, progress: @escaping (TransferEntity) -> Void) async throws -> TransferEntity {
        guard let result = uploadSupportFileResult, let transferEntity else {
            throw TransferErrorEntity.generic
        }
        
        start(transferEntity)
        
        let totalBytes: Int = 4
        
        for i in 1...Int(totalBytes) {
            try await Task.sleep(nanoseconds: UInt64(100_000_000))
            progress(TransferEntity(type: transferEntity.type, transferredBytes: i, totalBytes: totalBytes, path: transferEntity.path))
        }
        
        switch result {
        case .success(let transfer):
            return transfer
        case .failure(let error):
            throw error
        }
    }
    
    public func cancel(transfer: TransferEntity) async throws {
        if case .failure(let error) = cancelTransferResult {
            throw error
        }
    }
    
    public func cancel(transfer: TransferEntity, completion: @escaping (Result<Void, TransferErrorEntity>) -> Void) {
        completion(cancelTransferResult)
    }
    
    public func tempURL(forFilename filename: String) -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent(self.filename)
    }
    
    public func cancelUploadTransfers() { }
}
