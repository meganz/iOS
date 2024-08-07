import MEGAChatSdk
import MEGADomain
import MEGASdk
import MEGASDKRepo
import MEGASwift

public struct DownloadChatRepository: DownloadChatRepositoryProtocol {
    
    private let chatSdk: MEGAChatSdk
    private let sdk: MEGASdk
    
    private let cancelToken = ThreadSafeCancelToken()
    
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
        metaData: TransferMetaDataEntity?
    ) async throws -> TransferEntity {
        guard let node = chatSdk.chatNode(handle: nodeHandle, messageId: messageId, chatId: chatId) else {
            throw TransferErrorEntity.couldNotFindNodeByHandle
        }
        return try await withAsyncThrowingValue { completion in
            sdk.startDownloadNode(
                node,
                localPath: url.path,
                fileName: nil,
                appData: metaData?.rawValue,
                startFirst: true,
                cancelToken: cancelToken.value,
                collisionCheck: CollisionCheck.fingerprint,
                collisionResolution: CollisionResolution.newWithN,
                delegate: TransferDelegate { result in
                    switch result {
                    case .failure(let error):
                        completion(.failure(error))
                    case .success(let transfer):
                        completion(.success(transfer))
                    }
                }
            )
        }
    }
    
    public func downloadChatFile(
        forNodeHandle handle: HandleEntity,
        messageId: HandleEntity,
        chatId: HandleEntity,
        to url: URL,
        filename: String?,
        appdata: String?,
        startFirst: Bool
    ) throws -> AnyAsyncSequence<TransferEventEntity> {
        
        guard let node = chatSdk.chatNode(handle: handle, messageId: messageId, chatId: chatId), let name = node.name else {
            throw TransferErrorEntity.couldNotFindNodeByHandle
        }
        return try downloadFile(
            for: node,
            name: name,
            to: url,
            filename: filename,
            appdata: appdata,
            startFirst: startFirst,
            cancelToken: cancelToken
        )
    }
    
    // MARK: - Private
    private func downloadFile(
        for node: MEGANode,
        name: String,
        to url: URL,
        filename: String? = nil,
        appdata: String? = nil,
        startFirst: Bool,
        cancelToken: ThreadSafeCancelToken
    ) throws -> AnyAsyncSequence<TransferEventEntity> {
        let sequence: AnyAsyncSequence<TransferEventEntity> = AsyncThrowingStream(TransferEventEntity.self) { continuation in
            let offlineNameString = sdk.escapeFsIncompatible(name, destinationPath: url.path)
            let filePath = url.path + "/" + (offlineNameString ?? name)
            
            let transferDelegate = TransferDelegate { result in
                switch result {
                case .success(let transferEntity):
                    continuation.yield(.finish(transferEntity))
                    continuation.finish()
                case .failure(let error):
                    continuation.finish(throwing: error)
                }
            }
            
            transferDelegate.start = { transferEntity in
                continuation.yield(.start(transferEntity))
            }
            
            transferDelegate.progress = { transferEntity in
                continuation.yield(.update(transferEntity))
            }
            
            transferDelegate.folderUpdate = { folderTransferUpdateEntity in
                continuation.yield(.folderUpdate(folderTransferUpdateEntity))
            }
            
            sdk.startDownloadNode(
                node,
                localPath: filePath,
                fileName: filename,
                appData: appdata,
                startFirst: startFirst,
                cancelToken: cancelToken.value,
                collisionCheck: .fingerprint,
                collisionResolution: .newWithN,
                delegate: transferDelegate
            )
        }.eraseToAnyAsyncSequence()
        return sequence
    }
}
