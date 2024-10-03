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
    
    public func uploadFile(_ url: URL, toParent parent: HandleEntity, fileName: String?, appData: String?, isSourceTemporary: Bool, startFirst: Bool, start: ((TransferEntity) -> Void)?, update: ((TransferEntity) -> Void)?, completion: ((Result<TransferEntity, TransferErrorEntity>) -> Void)?) {
        guard let parentNode = sdk.node(forHandle: parent) else {
            completion?(.failure(TransferErrorEntity.couldNotFindNodeByHandle))
            return
        }

        guard let completion else {
            sdk.startUpload(withLocalPath: url.path, parent: parentNode, fileName: fileName, appData: appData, isSourceTemporary: isSourceTemporary, startFirst: startFirst, cancelToken: self.cancelToken.value)
            return
        }

        let transferDelegate = TransferDelegate(completion: completion)
        transferDelegate.start = start
        transferDelegate.progress = update

        sdk.startUpload(withLocalPath: url.path, parent: parentNode, fileName: fileName, appData: appData, isSourceTemporary: isSourceTemporary, startFirst: startFirst, cancelToken: self.cancelToken.value, delegate: transferDelegate)
    }
    
    public func uploadSupportFile(_ url: URL) async throws -> AnyAsyncSequence<FileUploadEvent> {
        let stream = AsyncThrowingStream<FileUploadEvent, Error> { continuation in
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
