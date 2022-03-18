struct UploadFileRepository: UploadFileRepositoryProtocol {
    private let sdk: MEGASdk
    
    init(sdk: MEGASdk) {
        self.sdk = sdk
    }
    
    func hasExistFile(name: String, parentHandle: MEGAHandle) -> Bool {
        guard let parent = sdk.node(forHandle: parentHandle) else { return false }
        let nodeList = sdk.nodeListSearch(for: parent, search: name, recursive: false)
        return nodeList.mnz_existsFile(withName: name)
    }
    
    func uploadFile(withLocalPath path: String, toParent parent: MEGAHandle, completion: @escaping (Result<TransferEntity, TransferErrorEntity>) -> Void) {
        guard let parentNode = sdk.node(forHandle: parent) else {
            completion(.failure(TransferErrorEntity.couldNotFindNodeByHandle))
            return
        }
        sdk.startUploadTopPriority(withLocalPath: path, parent: parentNode, appData: nil, isSourceTemporary: true, delegate: TransferDelegate(completion: completion))
    }
    
    func uploadSupportFile(atPath path: String, start: @escaping (TransferEntity) -> Void, progress: @escaping (TransferEntity) -> Void, completion: @escaping (Result<TransferEntity, TransferErrorEntity>) -> Void) {
        sdk.startUploadForSupport(withLocalPath: path, isSourceTemporary: false, delegate: TransferDelegate(start: start, progress: progress, completion: completion))
    }
    
    func cancel(transfer: TransferEntity, completion: @escaping (Result<Void, TransferErrorEntity>) -> Void) {
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
}
