
extension DownloadFileRepository {
    static let `default` = DownloadFileRepository(sdk: MEGASdkManager.sharedMEGASdk())
}

struct DownloadFileRepository: DownloadFileRepositoryProtocol {
    private let sdk: MEGASdk
    
    init(sdk: MEGASdk) {
        self.sdk = sdk
    }
    
    func download(nodeHandle: MEGAHandle, to path: String, appData: String?, completion: @escaping (Result<TransferEntity, TransferErrorEntity>) -> Void) {
        guard let node = sdk.node(forHandle: nodeHandle) else {
            completion(.failure(.couldNotFindNodeByHandle))
            return
        }
        
        sdk.startDownloadTopPriority(with: node, localPath: path, appData: appData, delegate: TransferDelegate(completion: completion))
    }
    
    func downloadToTempFolder(nodeHandle: MEGAHandle, appData: String?, progress: ((TransferEntity) -> Void)?, completion: @escaping (Result<TransferEntity, TransferErrorEntity>) -> Void) {
        downloadTo(folderPath: NSTemporaryDirectory(), nodeHandle: nodeHandle, appData: appData, progress: progress, completion: completion)
    }
    
    func downloadTo(folderPath: String, nodeHandle: MEGAHandle, appData: String?, progress: ((TransferEntity) -> Void)?, completion: @escaping (Result<TransferEntity, TransferErrorEntity>) -> Void) {
        guard let node = sdk.node(forHandle: nodeHandle),
              let base64Handle = node.base64Handle else {
                  completion(.failure(.couldNotFindNodeByHandle))
                  return
              }
        
        let nodeFolderPath = folderPath.append(pathComponent: base64Handle)
        
        guard let name = node.name else {
            completion(.failure(.nodeNameUndefined))
            return
        }
        
        let nodeFilePath = nodeFolderPath.append(pathComponent: name)
        
        do {
            try FileManager.default.createDirectory(atPath: nodeFolderPath, withIntermediateDirectories: true, attributes: nil)
            let transferDelegate: TransferDelegate
            if let progress = progress {
                transferDelegate = TransferDelegate(progress: progress, completion: completion)
            } else {
                transferDelegate = TransferDelegate(completion: completion)
            }
            sdk.startDownloadTopPriority(with: node, localPath: nodeFilePath, appData: appData, delegate: transferDelegate)
        } catch let error as NSError {
            completion(.failure(.createDirectory))
            MEGALogError("Create directory at path failed with error: \(error)")
        }
    }
}
