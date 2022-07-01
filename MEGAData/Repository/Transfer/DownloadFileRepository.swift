
extension DownloadFileRepository {
    static let `default` = DownloadFileRepository(sdk: MEGASdkManager.sharedMEGASdk())
}

struct DownloadFileRepository: DownloadFileRepositoryProtocol {
    private let sdk: MEGASdk
    private let chatSdk: MEGAChatSdk

    init(sdk: MEGASdk, chatSdk: MEGAChatSdk = MEGASdkManager.sharedMEGAChatSdk()) {
        self.sdk = sdk
        self.chatSdk = chatSdk
    }
    
    func download(nodeHandle: MEGAHandle, to path: String, appData: String?, cancelToken: MEGACancelToken?, completion: @escaping (Result<TransferEntity, TransferErrorEntity>) -> Void) {
        guard let node = sdk.node(forHandle: nodeHandle) else {
            completion(.failure(.couldNotFindNodeByHandle))
            return
        }
        
        sdk.startDownloadNode(node, localPath: path, fileName: nil, appData: appData, startFirst: true, cancelToken: cancelToken, delegate: TransferDelegate(completion: completion))
    }
    
    func downloadChat(nodeHandle: MEGAHandle, messageId: MEGAHandle, chatId: MEGAHandle, to path: String, appData: String?, cancelToken: MEGACancelToken?, completion: @escaping (Result<TransferEntity, TransferErrorEntity>) -> Void) {
        guard let message = chatSdk.message(forChat: chatId, messageId: messageId), let node = message.nodeList?.node(at: 0), nodeHandle == node.handle else {
            completion(.failure(.couldNotFindNodeByHandle))
            return
        }
        
        sdk.startDownloadNode(node, localPath: path, fileName: nil, appData: appData, startFirst: true, cancelToken: cancelToken, delegate: TransferDelegate(completion: completion))
    }
    
    func downloadToTempFolder(nodeHandle: MEGAHandle, appData: String?, cancelToken: MEGACancelToken?, progress: ((TransferEntity) -> Void)?, completion: @escaping (Result<TransferEntity, TransferErrorEntity>) -> Void) {
        downloadTo(folderPath: NSTemporaryDirectory(), nodeHandle: nodeHandle, appData: appData, cancelToken: cancelToken, progress: progress, completion: completion)
    }

    func downloadTo(folderPath: String, nodeHandle: MEGAHandle, appData: String?, cancelToken: MEGACancelToken?, progress: ((TransferEntity) -> Void)?, completion: @escaping (Result<TransferEntity, TransferErrorEntity>) -> Void) {
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
            sdk.startDownloadNode(node, localPath: nodeFilePath, fileName: nil, appData: appData, startFirst: true, cancelToken: cancelToken, delegate: transferDelegate)
        } catch let error as NSError {
            completion(.failure(.createDirectory))
            MEGALogError("Create directory at path failed with error: \(error)")
        }
    }
    
    func downloadFile(forNodeHandle handle: MEGAHandle, toPath localPath: String, filename: String?, appdata: String?, startFirst: Bool, cancelToken: MEGACancelToken, start: ((TransferEntity) -> Void)?, update: ((TransferEntity) -> Void)?, completion: ((Result<TransferEntity, TransferErrorEntity>) -> Void)?) {

        guard var node = sdk.node(forHandle: handle), let name = node.name else {
            completion?(.failure(TransferErrorEntity.couldNotFindNodeByHandle))
            return
        }
        
        if sdk == MEGASdkManager.sharedMEGASdkFolder() {
            guard let sharedNode = sdk.authorizeNode(node) else {
                completion?(.failure(TransferErrorEntity.couldNotFindNodeByHandle))
                return
            }
            node = sharedNode
        }
        
        downloadFile(for: node, name: name, localPath: localPath, completion: completion, start: start, update: update, filename: filename, appdata: appdata, startFirst: startFirst, cancelToken: cancelToken)
    }
    
    func downloadChatFile(forNodeHandle handle: MEGAHandle, messageId: MEGAHandle, chatId: MEGAHandle, toPath localPath: String, filename: String?, appdata: String?, startFirst: Bool, cancelToken: MEGACancelToken, start: ((TransferEntity) -> Void)?, update: ((TransferEntity) -> Void)?, completion: ((Result<TransferEntity, TransferErrorEntity>) -> Void)?) {
        
        guard let message = chatSdk.message(forChat: chatId, messageId: messageId), let node = message.nodeList?.node(at: 0), handle == node.handle, let name = node.name else {
            completion?(.failure(.couldNotFindNodeByHandle))
            return
        }
        
        downloadFile(for: node, name: name, localPath: localPath, completion: completion, start: start, update: update, filename: filename, appdata: appdata, startFirst: startFirst, cancelToken: cancelToken)
    }
    
    //MARK: - Private
    private func downloadFile(for node: MEGANode, name: String, localPath: String, completion: ((Result<TransferEntity, TransferErrorEntity>) -> Void)?, start: ((TransferEntity) -> Void)?, update: ((TransferEntity) -> Void)?, filename: String? = nil, appdata: String? = nil, startFirst: Bool, cancelToken: MEGACancelToken) {
        let offlineNameString = sdk.escapeFsIncompatible(name, destinationPath: NSHomeDirectory().appending("/"))
        let relativeFilePath =  localPath + "/" + (offlineNameString ?? name)

        if let completion = completion {
            let transferDelegate = TransferDelegate(completion: completion)
            if let start = start {
                transferDelegate.start = start
            }
            if let update = update {
                transferDelegate.progress = update
            }
            sdk.startDownloadNode(node, localPath: relativeFilePath, fileName: filename, appData: appdata, startFirst: startFirst, cancelToken: cancelToken, delegate: transferDelegate)
        } else {
            sdk.startDownloadNode(node, localPath: relativeFilePath, fileName: filename, appData: appdata, startFirst: startFirst, cancelToken: cancelToken)
        }
    }
}
