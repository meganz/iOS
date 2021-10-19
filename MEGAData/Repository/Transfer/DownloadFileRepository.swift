struct DownloadFileRepository: DownloadFileRepositoryProtocol {
    private let sdk: MEGASdk
    
    init(sdk: MEGASdk) {
        self.sdk = sdk
    }
    
    func downloadToTempFolder(nodeHandle: MEGAHandle, progress: @escaping (TransferEntity) -> Void, completion: @escaping (Result<TransferEntity, TransferErrorEntity>) -> Void) {
        guard let node = sdk.node(forHandle: nodeHandle),
              let base64Handle = node.base64Handle else {
                  completion(.failure(.couldNotFindNodeByHandle))
                  return
              }
        
        let nodeFolderPath = NSTemporaryDirectory().append(pathComponent: base64Handle)
        
        guard let name = node.name else {
            completion(.failure(.generic))
            return
        }
        
        let nodeFilePath = nodeFolderPath.append(pathComponent: name)
        
        do {
            try FileManager.default.createDirectory(atPath: nodeFolderPath, withIntermediateDirectories: true, attributes: nil)
            sdk.startDownloadTopPriority(with: node, localPath: nodeFilePath, appData: nil, delegate: TransferDelegate(progress: progress, completion: completion))
        } catch let error as NSError {
            completion(.failure(TransferErrorEntity.createDirectory))
            MEGALogError("Create directory at path failed with error: \(error)")
        }
    }
}
