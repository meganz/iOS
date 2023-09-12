import MEGADomain
import MEGASdk

public struct UploadFileRepository: UploadFileRepositoryProtocol {
    private let sdk: MEGASdk
    private let cancelToken = MEGACancelToken()

    public init(sdk: MEGASdk) {
        self.sdk = sdk
    }
    
    public func hasExistFile(name: String, parentHandle: HandleEntity) -> Bool {
        guard let parent = sdk.node(forHandle: parentHandle) else { return false }
        let nodeList = sdk.nodeListSearch(for: parent, search: name, recursive: false)
        return nodeList.existsFileWithName(name)
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
    
    public func uploadSupportFile(_ url: URL, start: @escaping (TransferEntity) -> Void, progress: @escaping (TransferEntity) -> Void, completion: @escaping (Result<TransferEntity, TransferErrorEntity>) -> Void) {
        sdk.startUploadForSupport(withLocalPath: url.path, isSourceTemporary: true, delegate: TransferDelegate(start: start, progress: progress, completion: completion))
    }
    
    public func cancel(transfer: TransferEntity, completion: @escaping (Result<Void, TransferErrorEntity>) -> Void) {
        guard let t = transfer.toMEGATransfer(in: sdk) else {
            completion(.failure(.generic))
            return
        }
        
        sdk.cancelTransfer(t, delegate: RequestDelegate { result in
            switch result {
            case .failure:
                completion(.failure(.generic))
            case .success:
                completion(.success(()))
            }
        })
    }
    
    public func cancelUploadTransfers() {
        if !cancelToken.isCancelled {
            cancelToken.cancel()
        }
    }
}
