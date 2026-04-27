import MEGADomain
import MEGASdk
import MEGASwift

public struct UploadFileRepository: UploadFileRepositoryProtocol {
    private let sdk: MEGASdk
    private let cancelToken = ThreadSafeCancelToken()

    public init(sdk: MEGASdk) {
        self.sdk = sdk
    }
    
    public func hasExistFile(name: String, parentHandle: HandleEntity) -> Bool {
        guard let parent = sdk.node(forHandle: parentHandle) else { return false }
        let node = sdk.childNode(forParent: parent, name: name, type: .file)
        return (node != nil)
    }

    public func resolvedFileName(
        _ name: String,
        inParent parentHandle: HandleEntity
    ) -> String {
        guard let parent = sdk.node(forHandle: parentHandle) else { return name }

        let url = URL(filePath: name, directoryHint: .notDirectory)
        let base = url.deletingPathExtension().lastPathComponent
        let ext = url.pathExtension

        let candidates = (0...Int.max).lazy.map { i -> String in
            let stem = i == 0 ? base : "\(base)_\(i)"
            return ext.isEmpty ? stem : "\(stem).\(ext)"
        }

        return candidates.first { candidate in
            sdk.childNode(forParent: parent, name: candidate, type: .file) == nil
        } ?? name
    }
    
    public func uploadFile(
        _ url: URL,
        toParent parent: HandleEntity,
        uploadOptions: UploadOptionsEntity,
        start: ((TransferEntity) -> Void)?,
        progress: ((TransferEntity) -> Void)?,
        completion: ((Result<TransferEntity, TransferErrorEntity>) -> Void)?
    ) {
        guard let completion else {
            sdk.startUpload(withLocalPath: url.path, parentHandle: parent, cancelToken: self.cancelToken.value, options: uploadOptions.toMEGAUploadOptions())
            return
        }
        
        let transferDelegate = TransferDelegate(completion: completion)
        transferDelegate.start = start
        transferDelegate.progress = progress
        
        sdk.startUpload(withLocalPath: url.path, parentHandle: parent, cancelToken: self.cancelToken.value, options: uploadOptions.toMEGAUploadOptions(), delegate: transferDelegate)
    }
    public func uploadFile(
        _ url: URL,
        toParent parent: HandleEntity,
        uploadOptions: UploadOptionsEntity,
        start: ((TransferEntity) -> Void)?,
        progress: ((TransferEntity) -> Void)?
    ) async throws -> TransferEntity {
        return try await withAsyncThrowingValue { completion in
            sdk.startUpload(withLocalPath: url.path,
                            parentHandle: parent,
                            cancelToken: self.cancelToken.value,
                            options: uploadOptions.toMEGAUploadOptions(),
                            delegate: TransferDelegate(start: start, progress: progress) { result in
                switch result {
                case .success(let transfer):
                    completion(.success(transfer))
                case .failure(let error):
                    completion(.failure(error))
                }
            })
        }
    }
    
    public func uploadSupportFile(_ url: URL) async throws -> AnyAsyncSequence<FileUploadEvent> {
        let stream = AsyncThrowingStream<FileUploadEvent, any Error> { continuation in
            let start: (TransferEntity) -> Void = { transferEntity in
                continuation.yield(.start(transferEntity))
            }
            
            let progress: (TransferEntity) -> Void = { transferEntity in
                continuation.yield(.progress(transferEntity))
            }
            
            let completion: (Result<TransferEntity, TransferErrorEntity>) -> Void = { result in
                switch result {
                case .success(let transferEntity):
                    continuation.yield(.completion(transferEntity))
                    continuation.finish()
                case .failure(let error):
                    continuation.finish(throwing: error)
                }
            }
            
            let delegate = TransferDelegate(start: start, progress: progress, completion: completion)
            
            sdk.startUploadForSupport(withLocalPath: url.path, isSourceTemporary: true, delegate: delegate)
        }

        return stream.eraseToAnyAsyncSequence()
    }
    
    public func cancel(transfer: TransferEntity) async throws {
        guard let transfer = transfer.toMEGATransfer(in: sdk) else {
            throw TransferErrorEntity.generic
        }
        
        return try await withAsyncThrowingValue { continuation in
            sdk.cancelTransfer(transfer, delegate: RequestDelegate { result in
                switch result {
                case .failure:
                    continuation(.failure(TransferErrorEntity.generic))
                case .success:
                    continuation(.success)
                }
            })
        }
    }
    
    public func cancelUploadTransfers() {
        cancelToken.cancel()
    }
}
