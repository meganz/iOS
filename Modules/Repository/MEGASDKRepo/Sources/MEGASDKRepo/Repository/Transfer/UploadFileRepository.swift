import MEGADomain
import MEGASdk
import MEGASwift

public struct UploadFileRepository: UploadFileRepositoryProtocol {
    private let sdk: MEGASdk
    private let cancelToken = MEGACancelToken()

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
            sdk.startUpload(withLocalPath: url.path, parent: parentNode, fileName: fileName, appData: appData, isSourceTemporary: isSourceTemporary, startFirst: startFirst, cancelToken: self.cancelToken)
            return
        }

        let transferDelegate = TransferDelegate(completion: completion)
        transferDelegate.start = start
        transferDelegate.progress = update

        sdk.startUpload(withLocalPath: url.path, parent: parentNode, fileName: fileName, appData: appData, isSourceTemporary: isSourceTemporary, startFirst: startFirst, cancelToken: self.cancelToken, delegate: transferDelegate)
    }
    
    public func uploadSupportFile(
        _ url: URL,
        start: @escaping (TransferEntity) -> Void,
        progress: @escaping (TransferEntity) -> Void
    ) async throws -> TransferEntity {
        try await withAsyncThrowingValue { continuation in
            sdk.startUploadForSupport(
                withLocalPath: url.path,
                isSourceTemporary: true,
                delegate: TransferDelegate(
                    start: start,
                    progress: progress,
                    completion: { result in
                        switch result {
                        case .success(let transfer):
                            continuation(.success(transfer))
                        case .failure(let error):
                            continuation(.failure(error))
                        }
                    }
                )
            )
        }
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
        if !cancelToken.isCancelled {
            cancelToken.cancel()
        }
    }
}
