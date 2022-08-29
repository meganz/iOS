import MEGADomain
import Foundation

struct DownloadFileRepository: DownloadFileRepositoryProtocol {
    static var newRepo: DownloadFileRepository {
        DownloadFileRepository(sdk: MEGASdkManager.sharedMEGASdk(), sharedFolderSdk: nil, chatSdk: MEGASdkManager.sharedMEGAChatSdk())
    }
    
    private let sdk: MEGASdk
    private let sharedFolderSdk: MEGASdk?
    private let chatSdk: MEGAChatSdk

    init(sdk: MEGASdk, sharedFolderSdk: MEGASdk? = nil, chatSdk: MEGAChatSdk = MEGASdkManager.sharedMEGAChatSdk()) {
        self.sdk = sdk
        self.sharedFolderSdk = sharedFolderSdk
        self.chatSdk = chatSdk
    }
    
    func download(nodeHandle: HandleEntity, to url: URL, appData: String?, cancelToken: MEGACancelToken?, completion: @escaping (Result<TransferEntity, TransferErrorEntity>) -> Void) {
        var megaNode: MEGANode
        
        if let sharedFolderSdk = sharedFolderSdk {
            guard let node = sharedFolderSdk.node(forHandle: nodeHandle), let sharedNode = sharedFolderSdk.authorizeNode(node) else {
                completion(.failure(TransferErrorEntity.couldNotFindNodeByHandle))
                return
            }
            megaNode = sharedNode
        } else {
            guard let node = sdk.node(forHandle: nodeHandle) else {
                completion(.failure(TransferErrorEntity.couldNotFindNodeByHandle))
                return
            }
            megaNode = node
        }
        
        sdk.startDownloadNode(megaNode, localPath: url.path, fileName: nil, appData: appData, startFirst: true, cancelToken: cancelToken, delegate: TransferDelegate(completion: completion))
    }
    
    func downloadChat(nodeHandle: HandleEntity, messageId: HandleEntity, chatId: HandleEntity, to url: URL, appData: String?, cancelToken: MEGACancelToken?, completion: @escaping (Result<TransferEntity, TransferErrorEntity>) -> Void) {
        guard let node = chatNode(handle: nodeHandle, messageId: messageId, chatId: chatId) else {
            completion(.failure(.couldNotFindNodeByHandle))
            return
        }
        
        sdk.startDownloadNode(node, localPath: url.path, fileName: nil, appData: appData, startFirst: true, cancelToken: cancelToken, delegate: TransferDelegate(completion: completion))
    }

    func downloadTo(_ url: URL, nodeHandle: HandleEntity, appData: String?, cancelToken: MEGACancelToken?, progress: ((TransferEntity) -> Void)?, completion: @escaping (Result<TransferEntity, TransferErrorEntity>) -> Void) {
        guard let node = sdk.node(forHandle: nodeHandle),
              let base64Handle = node.base64Handle else {
                  completion(.failure(.couldNotFindNodeByHandle))
                  return
              }
        
        let nodeFolderPath = url.path.append(pathComponent: base64Handle)
        
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
    
    func downloadFile(forNodeHandle handle: HandleEntity, to url: URL, filename: String?, appdata: String?, startFirst: Bool, cancelToken: MEGACancelToken, start: ((TransferEntity) -> Void)?, update: ((TransferEntity) -> Void)?, completion: ((Result<TransferEntity, TransferErrorEntity>) -> Void)?) {
        var megaNode: MEGANode
        var nodeName: String
        
        if let sharedFolderSdk = sharedFolderSdk {
            guard let node = sharedFolderSdk.node(forHandle: handle), let sharedNode = sharedFolderSdk.authorizeNode(node), let name = node.name else {
                completion?(.failure(TransferErrorEntity.couldNotFindNodeByHandle))
                return
            }
            nodeName = name
            megaNode = sharedNode
        } else {
            guard let node = sdk.node(forHandle: handle), let name = node.name else {
                completion?(.failure(TransferErrorEntity.couldNotFindNodeByHandle))
                return
            }
            nodeName = name
            megaNode = node
        }
        
        downloadFile(for: megaNode, name: nodeName, to: url, completion: completion, start: start, update: update, filename: filename, appdata: appdata, startFirst: startFirst, cancelToken: cancelToken)
    }
    
    func downloadChatFile(forNodeHandle handle: HandleEntity, messageId: HandleEntity, chatId: HandleEntity, to url: URL, filename: String?, appdata: String?, startFirst: Bool, cancelToken: MEGACancelToken, start: ((TransferEntity) -> Void)?, update: ((TransferEntity) -> Void)?, completion: ((Result<TransferEntity, TransferErrorEntity>) -> Void)?) {
        
        guard let node = chatNode(handle: handle, messageId: messageId, chatId: chatId), let name = node.name else {
            completion?(.failure(.couldNotFindNodeByHandle))
            return
        }
        
        downloadFile(for: node, name: name, to: url, completion: completion, start: start, update: update, filename: filename, appdata: appdata, startFirst: startFirst, cancelToken: cancelToken)
    }

    func downloadFileLink(_ fileLink: FileLinkEntity, named name: String, to url: URL, transferMetaData: TransferMetaDataEntity?, startFirst: Bool, cancelToken: MEGACancelToken?, start: ((TransferEntity) -> Void)?, update: ((TransferEntity) -> Void)?, completion: ((Result<TransferEntity, TransferErrorEntity>) -> Void)?) {
        sdk.publicNode(forMegaFileLink: fileLink.linkURL.absoluteString, delegate: MEGAGetPublicNodeRequestDelegate(completion: { (request, error) in
            guard let error = error, error.type == .apiOk, let node = request?.publicNode else {
                completion?(.failure(.couldNotFindNodeByLink))
                return
            }
            
            downloadFile(for: node, name: name, to: url, completion: completion, start: start, update: update, filename: nil, appdata: transferMetaData?.metaData, startFirst: startFirst, cancelToken: cancelToken)
        }))
    }
    
    //MARK: - Private
    private func downloadFile(for node: MEGANode, name: String, to url: URL, completion: ((Result<TransferEntity, TransferErrorEntity>) -> Void)?, start: ((TransferEntity) -> Void)?, update: ((TransferEntity) -> Void)?, filename: String? = nil, appdata: String? = nil, startFirst: Bool, cancelToken: MEGACancelToken?) {
        let offlineNameString = sdk.escapeFsIncompatible(name, destinationPath: url.path)
        let filePath = url.path + "/" + (offlineNameString ?? name)

        if let completion = completion {
            let transferDelegate = TransferDelegate(completion: completion)
            if let start = start {
                transferDelegate.start = start
            }
            if let update = update {
                transferDelegate.progress = update
            }
            sdk.startDownloadNode(node, localPath: filePath, fileName: filename, appData: appdata, startFirst: startFirst, cancelToken: cancelToken, delegate: transferDelegate)
        } else {
            sdk.startDownloadNode(node, localPath: filePath, fileName: filename, appData: appdata, startFirst: startFirst, cancelToken: cancelToken)
        }
    }
    
    private func chatNode(handle: HandleEntity, messageId: HandleEntity, chatId: HandleEntity) -> MEGANode? {
        if let message = chatSdk.message(forChat: chatId, messageId: messageId), let node = message.nodeList?.node(at: 0), handle == node.handle {
            return node
        } else if let messageForNodeHistory = chatSdk.messageFromNodeHistory(forChat: chatId, messageId: messageId), let node = messageForNodeHistory.nodeList?.node(at: 0), handle == node.handle {
            return node
        } else {
            return nil
        }
    }
}
