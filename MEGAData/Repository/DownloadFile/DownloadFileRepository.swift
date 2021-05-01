struct DownloadFileRepository: DownloadFileRepositoryProtocol {
    private let sdk: MEGASdk
    
    init(sdk: MEGASdk) {
        self.sdk = sdk
    }
    
    func downloadToTempFolder(nodeHandle: MEGAHandle, progress: @escaping (TransferEntity) -> Void, completion: @escaping (Result<TransferEntity, TransferErrorEntity>) -> Void) {
        guard let node = sdk.node(forHandle: nodeHandle) else { return }
        let nodeFolderPath = NSTemporaryDirectory().append(pathComponent: node.base64Handle)
        let nodeFilePath = nodeFolderPath.append(pathComponent: node.name)
        
        do {
            try FileManager.default.createDirectory(atPath: nodeFolderPath, withIntermediateDirectories: true, attributes: nil)
            sdk.startDownloadTopPriority(with: node, localPath: nodeFilePath, appData: nil, delegate: TransferDelegate(progress: progress, completion: completion))
        } catch let error as NSError {
            completion(.failure(TransferErrorEntity.createDirectory))
            MEGALogError("Create directory at path failed with error: \(error)")
        }
    }
}
