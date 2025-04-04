import Foundation
import MEGADomain
import MEGASdk
import MEGASwift

public struct DownloadFileRepository: DownloadFileRepositoryProtocol {
    
    public static var newRepo: DownloadFileRepository {
        let sdk = MEGASdk.sharedSdk
        return DownloadFileRepository(
            sdk: sdk,
            sharedFolderSdk: nil,
            nodeProvider: DefaultMEGANodeProvider(sdk: sdk))
    }
    
    private let sdk: MEGASdk
    private let sharedFolderSdk: MEGASdk?
    private let nodeProvider: any MEGANodeProviderProtocol
    private let cancelToken = ThreadSafeCancelToken()

    public init(sdk: MEGASdk, sharedFolderSdk: MEGASdk? = nil, nodeProvider: some MEGANodeProviderProtocol = DefaultMEGANodeProvider(sdk: .sharedSdk)) {
        self.sdk = sdk
        self.sharedFolderSdk = sharedFolderSdk
        self.nodeProvider = nodeProvider
    }
    
    public func download(nodeHandle: HandleEntity, to url: URL, metaData: TransferMetaDataEntity?) async throws -> TransferEntity {
        let megaNode: MEGANode

        if let sharedFolderSdk = sharedFolderSdk {
            guard let node = sharedFolderSdk.node(forHandle: nodeHandle),
                  let sharedNode = sharedFolderSdk.authorizeNode(node) else {
                throw TransferErrorEntity.couldNotFindNodeByHandle
            }
            megaNode = sharedNode
        } else {
            guard let node = await nodeProvider.node(for: nodeHandle) else {
                throw TransferErrorEntity.couldNotFindNodeByHandle
            }
            megaNode = node
        }
                
        return try await withAsyncThrowingValue { continuation in
            sdk.startDownloadNode(
                megaNode,
                localPath: url.path,
                fileName: nil,
                appData: metaData?.rawValue,
                startFirst: true,
                cancelToken: cancelToken.value,
                collisionCheck: CollisionCheck.fingerprint,
                collisionResolution: CollisionResolution.newWithN,
                delegate: TransferDelegate(completion: { result in continuation(result.mapError { $0 }) })
            )
        }
    }
        
    public func downloadTo(_ url: URL, nodeHandle: HandleEntity, appData: String?) throws -> AnyAsyncSequence<TransferEventEntity> {
        guard let node = sdk.node(forHandle: nodeHandle),
              let base64Handle = node.base64Handle else {
            throw TransferErrorEntity.couldNotFindNodeByHandle
        }
        
        guard let name = node.name else {
            throw TransferErrorEntity.nodeNameUndefined
        }
        
        let nodeFolderPath = url.path.append(pathComponent: base64Handle)
        let nodeFilePath = nodeFolderPath.append(pathComponent: name)

        do {
            try FileManager.default.createDirectory(
                atPath: nodeFolderPath,
                withIntermediateDirectories: true,
                attributes: nil
            )
        } catch {
            throw TransferErrorEntity.createDirectory
        }
        
        let sequence: AnyAsyncSequence<TransferEventEntity> = AsyncThrowingStream(TransferEventEntity.self) { continuation in
            
            let transferDelegate = TransferDelegate { result in
                switch result {
                case .success(let transferEntity):
                    continuation.yield(.finish(transferEntity))
                    continuation.finish()
                case .failure(let error):
                    continuation.finish(throwing: error)
                }
            }
            
            transferDelegate.progress = { transferEntity in
                continuation.yield(.update(transferEntity))
            }
            
            sdk.startDownloadNode(
                node,
                localPath: nodeFilePath,
                fileName: nil,
                appData: appData,
                startFirst: true,
                cancelToken: cancelToken.value,
                collisionCheck: CollisionCheck.fingerprint,
                collisionResolution: CollisionResolution.newWithN,
                delegate: transferDelegate
            )

        }.eraseToAnyAsyncSequence()
        return sequence
    }
    
    public func downloadFile(
        forNodeHandle handle: HandleEntity,
        to url: URL,
        filename: String?,
        appdata: String?,
        startFirst: Bool
    ) throws -> AnyAsyncSequence<TransferEventEntity> {
        
        var megaNode: MEGANode
        var nodeName: String
        
        if let sharedFolderSdk = sharedFolderSdk {
            guard let node = sharedFolderSdk.node(forHandle: handle),
                  let sharedNode = sharedFolderSdk.authorizeNode(node),
                  let name = node.name
            else {
                throw TransferErrorEntity.couldNotFindNodeByHandle
            }
            nodeName = name
            megaNode = sharedNode
        } else {
            guard let node = sdk.node(forHandle: handle),
                  let name = node.name
            else {
                throw TransferErrorEntity.couldNotFindNodeByHandle
            }
            nodeName = name
            megaNode = node
        }
        
        let offlineNameString = sdk.escapeFsIncompatible(nodeName, destinationPath: url.path)
        let filePath = url.path + "/" + (offlineNameString ?? nodeName)
        
        let sequence: AnyAsyncSequence<TransferEventEntity> = AsyncThrowingStream(TransferEventEntity.self) { continuation in
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
                megaNode,
                localPath: filePath,
                fileName: filename,
                appData: appdata,
                startFirst: startFirst,
                cancelToken: cancelToken.value,
                collisionCheck: CollisionCheck.fingerprint,
                collisionResolution: CollisionResolution.newWithN,
                delegate: transferDelegate
            )
        }.eraseToAnyAsyncSequence()
        
        return sequence        
    }
    
    public func downloadFileLink(
        _ fileLink: FileLinkEntity,
        named name: String,
        to url: URL,
        metaData: TransferMetaDataEntity?,
        startFirst: Bool
    ) throws -> AnyAsyncSequence<TransferEventEntity> {
        let offlineNameString = sdk.escapeFsIncompatible(name, destinationPath: url.path)
        let filePath = url.path + "/" + (offlineNameString ?? name)
        
        let sequence: AnyAsyncSequence<TransferEventEntity> = AsyncThrowingStream(TransferEventEntity.self) { continuation in
            sdk.publicNode(
                forMegaFileLink: fileLink.linkURL.absoluteString,
                delegate: RequestDelegate { result in
                    switch result {
                    case .success(let request):
                        guard let node = request.publicNode else {
                            continuation.finish(throwing: TransferErrorEntity.couldNotFindNodeByLink)
                            return
                        }
                        sdk.startDownloadNode(
                            node,
                            localPath: filePath,
                            fileName: name,
                            appData: metaData?.rawValue,
                            startFirst: startFirst,
                            cancelToken: cancelToken.value,
                            collisionCheck: CollisionCheck.fingerprint,
                            collisionResolution: CollisionResolution.newWithN
                        )
                    case .failure(let error):
                        continuation.finish(throwing: error)
                    }
                }
            )
        }.eraseToAnyAsyncSequence()
        
        return sequence
    }
    
    public func cancelDownloadTransfers() {
        cancelToken.cancel()
    }
}
