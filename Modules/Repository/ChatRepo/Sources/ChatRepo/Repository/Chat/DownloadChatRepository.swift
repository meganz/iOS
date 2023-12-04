import MEGAChatSdk
import MEGADomain
import MEGASdk
import MEGASDKRepo

public struct DownloadChatRepository: DownloadChatRepositoryProtocol {
    
    private let chatSdk: MEGAChatSdk
    private let sdk: MEGASdk
    
    private let cancelToken = MEGACancelToken()
    
    public static var newRepo: DownloadChatRepository {
        DownloadChatRepository(chatSdk: .sharedChatSdk, sdk: .sharedSdk)
    }
    
    public init(chatSdk: MEGAChatSdk, sdk: MEGASdk) {
        self.chatSdk = chatSdk
        self.sdk = sdk
    }
    
    public func downloadChat(
        nodeHandle: HandleEntity,
        messageId: HandleEntity,
        chatId: HandleEntity,
        to url: URL,
        metaData: TransferMetaDataEntity?,
        completion: @escaping (Result<TransferEntity, TransferErrorEntity>) -> Void
    ) {
        guard let node = chatSdk.chatNode(handle: nodeHandle, messageId: messageId, chatId: chatId) else {
            completion(.failure(.couldNotFindNodeByHandle))
            return
        }
        
        sdk.startDownloadNode(
            node,
            localPath: url.path,
            fileName: nil,
            appData: metaData?.rawValue,
            startFirst: true,
            cancelToken: cancelToken,
            collisionCheck: CollisionCheck.fingerprint,
            collisionResolution: CollisionResolution.newWithN,
            delegate: TransferDelegate(completion: completion)
        )
    }
    
    public func downloadChatFile(
        forNodeHandle handle: HandleEntity,
        messageId: HandleEntity,
        chatId: HandleEntity,
        to url: URL,
        filename: String?,
        appdata: String?,
        startFirst: Bool,
        start: ((TransferEntity) -> Void)?,
        update: ((TransferEntity) -> Void)?,
        completion: ((Result<TransferEntity, TransferErrorEntity>) -> Void)?
    ) {
        
        guard let node = chatSdk.chatNode(handle: handle, messageId: messageId, chatId: chatId), let name = node.name else {
            completion?(.failure(.couldNotFindNodeByHandle))
            return
        }
        
        downloadFile(
            for: node,
            name: name,
            to: url,
            completion: completion,
            start: start,
            update: update,
            filename: filename,
            appdata: appdata,
            startFirst: startFirst,
            cancelToken: self.cancelToken
        )
    }
    
    // MARK: - Private
    private func downloadFile(
        for node: MEGANode,
        name: String,
        to url: URL,
        completion: ((Result<TransferEntity, TransferErrorEntity>) -> Void)?,
        start: ((TransferEntity) -> Void)?,
        update: ((TransferEntity) -> Void)?,
        folderUpdate: ((FolderTransferUpdateEntity) -> Void)? = nil,
        filename: String? = nil,
        appdata: String? = nil,
        startFirst: Bool,
        cancelToken: MEGACancelToken?
    ) {
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
            if let folderUpdate = folderUpdate {
                transferDelegate.folderUpdate = folderUpdate
            }
            sdk.startDownloadNode(
                node,
                localPath: filePath,
                fileName: filename,
                appData: appdata,
                startFirst: startFirst,
                cancelToken: cancelToken,
                collisionCheck: CollisionCheck.fingerprint,
                collisionResolution: CollisionResolution.newWithN,
                delegate: transferDelegate
            )
        } else {
            sdk.startDownloadNode(
                node,
                localPath: filePath,
                fileName: filename,
                appData: appdata,
                startFirst: startFirst,
                cancelToken: cancelToken,
                collisionCheck: CollisionCheck.fingerprint,
                collisionResolution: CollisionResolution.newWithN
            )
        }
    }
}
