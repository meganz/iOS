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
        let megaNode = try await megaNode(for: nodeHandle)

        return try await withAsyncThrowingValue { continuation in
            startDownload(
                of: megaNode,
                to: url,
                metaData: metaData,
                delegate: TransferDelegate(completion: { result in continuation(result.mapError { $0 }) })
            )
        }
    }

    public func downloadFolder(
        nodeHandle: HandleEntity,
        to url: URL,
        metaData: TransferMetaDataEntity?
    ) async throws -> FolderDownloadResultEntity {
        let megaNode = try await megaNode(for: nodeHandle)
        let progress = FolderDownloadProgress()

        // Counted from the global transfer stream, where every transfer this SDK runs arrives — the
        // folder's own tag is what tells its files apart from the rest. Registered on the SDK that is
        // about to run the download rather than on an app wide listener, so what is counted cannot drift
        // from where the files are coming from.
        //
        // Recorded straight from the callback rather than over `transferFinishUpdates`, because a sub
        // transfer is reported once and never again. The SDK calls globally registered transfer delegates
        // before the folder transfer's own, so counting has finished before this download is told it is
        // over, which handing the callbacks to a consuming task first would not guarantee.
        let subTransfers = TransferDelegate { result in
            guard case let .success(transfer) = result else { return }
            progress.record(transfer)
        }
        sdk.add(subTransfers)
        defer { sdk.remove(subTransfers) }

        do {
            // Typed rather than inferred: the folder transfer itself is of no interest here — only what the
            // files under it did — but the continuation has nothing else to pin its value type to.
            let _: TransferEntity = try await withAsyncThrowingValue { continuation in
                startDownload(
                    of: megaNode,
                    to: url,
                    metaData: metaData,
                    delegate: TransferDelegate(
                        // The folder transfer's own start, fired before it scans anything, is where its tag
                        // comes from. There is no other way to tell our files apart from those of any other
                        // folder download running at the same time.
                        start: { progress.setFolderTransferTag($0.tag) },
                        completion: { result in continuation(result.mapError { $0 }) },
                        folderUpdate: { progress.noteFolderUpdate($0) }
                    )
                )
            }
            return progress.result(isSuccess: true)
        } catch TransferErrorEntity.download {
            // Reported rather than thrown: a folder comes back with this whether one file inside it failed
            // or none of them ever started, and only the counts tell those two apart. Cancellation stays an
            // error, since a user who stopped it themselves has nothing to be told.
            let result = progress.result(isSuccess: false)
            guard result.fileCount == 0 else { return result }

            return FolderDownloadResultEntity(
                isSuccess: false,
                fileCount: await fileCount(of: megaNode),
                downloadedFileCount: result.downloadedFileCount
            )
        }
    }

    private func fileCount(of node: MEGANode) async -> Int {
        // Whichever SDK the node came from, since only that one has it in its tree — see `megaNode(for:)`.
        await withAsyncValue { completion in
            (sharedFolderSdk ?? sdk).getFolderInfo(for: node, delegate: RequestDelegate { result in
                completion(.success((try? result.get())?.megaFolderInfo?.files ?? 0))
            })
        }
    }

    private func megaNode(for nodeHandle: HandleEntity) async throws -> MEGANode {
        if let sharedFolderSdk {
            guard let node = sharedFolderSdk.node(forHandle: nodeHandle),
                  let sharedNode = sharedFolderSdk.authorizeNode(node) else {
                throw TransferErrorEntity.couldNotFindNodeByHandle
            }
            return sharedNode
        } else {
            guard let node = await nodeProvider.node(for: nodeHandle) else {
                throw TransferErrorEntity.couldNotFindNodeByHandle
            }
            return node
        }
    }

    private func startDownload(
        of node: MEGANode,
        to url: URL,
        metaData: TransferMetaDataEntity?,
        delegate: TransferDelegate
    ) {
        sdk.startDownloadNode(
            node,
            localPath: url.path,
            fileName: nil,
            appData: metaData?.rawValue,
            startFirst: true,
            cancelToken: cancelToken.value,
            collisionCheck: CollisionCheck.fingerprint,
            collisionResolution: CollisionResolution.newWithN,
            delegate: delegate
        )
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
