import Foundation
import MEGADomain
import MEGAFoundation
import MEGASdk
import MEGASwift

public struct DownloadFileRepository: DownloadFileRepositoryProtocol {
    private let sdk: MEGASdk
    private let sharedFolderSdk: MEGASdk?
    private let chatNodeProvider: any ChatMEGANodeProviding
    private let nodeProvider: any MEGANodeProviderProtocol
    private let transferQuotaNotifier: any TransferQuotaStateNotifying
    private let preresolvedNodes: [HandleEntity: MEGANode]
    private let cancelToken = ThreadSafeCancelToken()

    /// - Parameter preresolvedNodes: Nodes the caller has already resolved, for the sources that cannot be
    ///   looked up in any SDK tree -- a public album link's photos come from a set preview, and fetching
    ///   one suspends, which the transfers this repository starts synchronously cannot do. Resolving them
    ///   up front is what keeps that suspension at the album screen instead of down here.
    public init(sdk: MEGASdk,
                sharedFolderSdk: MEGASdk? = nil,
                nodeProvider: any MEGANodeProviderProtocol = DefaultMEGANodeProvider(sdk: .sharedSdk),
                chatNodeProvider: some ChatMEGANodeProviding,
                transferQuotaNotifier: some TransferQuotaStateNotifying = DownloadTransferQuotaStateProvider.shared,
                preresolvedNodes: [HandleEntity: MEGANode] = [:]) {
        self.sdk = sdk
        self.sharedFolderSdk = sharedFolderSdk
        self.nodeProvider = nodeProvider
        self.chatNodeProvider = chatNodeProvider
        self.preresolvedNodes = preresolvedNodes
        self.transferQuotaNotifier = transferQuotaNotifier
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
    
    public func downloadProgress(batch: [DownloadBatchItemEntity]) -> AnyAsyncThrowingSequence<TransferEventEntity, any Error> {
        return AsyncThrowingStream(TransferEventEntity.self) { continuation in
            let task = Task {
                let itemList = await buildDownloadItemList(from: batch)
                MEGALog.log(
                    level: .info,
                    message: "[DownloadFileRepository] starting download batch: \(itemList.size) of \(batch.count) item(s) resolved"
                )

                guard !Task.isCancelled else {
                    MEGALog.log(level: .debug, message: "[DownloadFileRepository] download batch cancelled")
                    continuation.finish(throwing: TransferErrorEntity.cancelled)
                    return
                }

                let transferDelegate = TransferDelegate { result in
                    switch result {
                    case .success(let transferEntity):
                        continuation.yield(.finish(transferEntity))
                        continuation.finish()
                    case .failure(let error):
                        MEGALog.log(level: .error, message: "[DownloadFileRepository] download batch transfer failed: \(error)")
                        continuation.finish(throwing: error)
                    }
                }
                
                transferDelegate.start = { continuation.yield(.start($0)) }
                transferDelegate.progress = { continuation.yield(.update($0)) }
                transferDelegate.folderUpdate = { continuation.yield(.folderUpdate($0)) }
                transferDelegate.transferQuotaState = { [transferQuotaNotifier] state in
                    MEGALog.log(level: .info, message: "[DownloadFileRepository] download batch predicted transfer quota state: \(state)")
                    transferQuotaNotifier.notify(state: state)
                }
                
                sdk.startDownloadBatch(
                    withItems: itemList,
                    cancelToken: cancelToken.value,
                    collisionCheck: CollisionCheck.fingerprint,
                    collisionResolution: CollisionResolution.newWithN,
                    delegate: transferDelegate
                )
            }
            
            continuation.onTermination = { _ in task.cancel() }
        }.eraseToAnyAsyncThrowingSequence()
    }
    
    public func download(batch: [DownloadBatchItemEntity]) async throws {
        _ = try await downloadProgress(batch: batch).first(where: \.isTerminal)
    }

    private func fileCount(of node: MEGANode) async -> Int {
        // Whichever SDK the node came from, since only that one has it in its tree — see `megaNode(for:)`.
        await withAsyncValue { completion in
            (sharedFolderSdk ?? sdk).getFolderInfo(for: node, delegate: RequestDelegate { result in
                completion(.success((try? result.get())?.megaFolderInfo?.files ?? 0))
            })
        }
    }

    private func buildDownloadItemList(from batch: [DownloadBatchItemEntity]) async -> MEGADownloadItemList {
        let itemList = MEGADownloadItemList()
        let items: [(DownloadBatchItemEntity, MEGANode?)] = await batch.taskGroup(maxConcurrentTasks: 3) { item in
            do {
                return (item, try await megaNode(for: item.source))
            } catch {
                MEGALog.log(
                    level: .error,
                    message: "[DownloadFileRepository] download item dropped \(error)"
                )
                return (item, nil)
            }
        }
        
        for (item, node) in items {
            guard let node else { continue }
            itemList.add(
                node,
                localPath: item.destination.toSDKLocalPath,
                customName: item.destination.toSDKCustomName,
                appData: item.appData,
                startFirst: item.startFirst,
                undelete: false
            )
        }

        return itemList
    }
    
    private func megaNode(for source: DownloadBatchItemEntity.Source) async throws -> MEGANode {
        switch source {
        case let .node(handle):
            return try await megaNode(for: handle)
        case let .chatNode(handle, messageId, chatId):
            return try await megaNode(handle: handle, messageId: messageId, chatId: chatId)
        case let .fileLink(fileLink):
            return try await nodeFor(fileLink: fileLink)
        }
    }

    private func megaNode(
        handle: HandleEntity,
        messageId: HandleEntity,
        chatId: HandleEntity
    ) async throws -> MEGANode {
        guard let node = await chatNodeProvider.node(handle: handle, messageId: messageId, chatId: chatId) else {
            throw TransferErrorEntity.couldNotFindNodeByHandle
        }
        return node
    }
    
    private func nodeFor(fileLink: FileLinkEntity) async throws -> MEGANode {
        try await withCheckedThrowingContinuation { continuation in
            sdk.publicNode(forMegaFileLink: fileLink.linkURL.absoluteString, delegate: RequestDelegate { result in
                switch result {
                case .success(let request):
                    guard let node = request.publicNode else {
                        continuation.resume(throwing: NodeErrorEntity.nodeNotFound)
                        return
                    }
                    continuation.resume(returning: node)
                case .failure:
                    continuation.resume(throwing: NodeErrorEntity.nodeNotFound)
                }
            })
        }
    }

    private func megaNode(for nodeHandle: HandleEntity) async throws -> MEGANode {
        if let sharedFolderNode = try sharedFolderNode(for: nodeHandle) {
            return sharedFolderNode
        }
        
        if let preresolvedNode = preresolvedNodes[nodeHandle] {
           return preresolvedNode
        }
        
        guard let node = await nodeProvider.node(for: nodeHandle) else {
            throw TransferErrorEntity.couldNotFindNodeByHandle
        }
        return node
    }
    
    /// The node for a transfer that has to be started without suspending.
    ///
    /// Everything the account owns is in the tree already, so only a source that is outside it has to be
    /// resolved ahead of time and handed over as `preresolvedNodes`.
    private func resolvedMEGANode(for nodeHandle: HandleEntity) throws -> MEGANode {
        if let sharedFolderNode = try sharedFolderNode(for: nodeHandle) {
            return sharedFolderNode
        }
        
        guard let node = preresolvedNodes[nodeHandle] ?? sdk.node(forHandle: nodeHandle) else {
            throw TransferErrorEntity.couldNotFindNodeByHandle
        }
        return node
    }
    
    /// The authorized node, when this repository is downloading out of a folder link. `nil` when it is not.
    private func sharedFolderNode(for nodeHandle: HandleEntity) throws -> MEGANode? {
        guard let sharedFolderSdk else { return nil }
        
        guard let node = sharedFolderSdk.node(forHandle: nodeHandle),
              let sharedNode = sharedFolderSdk.authorizeNode(node) else {
            throw TransferErrorEntity.couldNotFindNodeByHandle
        }
        return sharedNode
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
        let megaNode = try resolvedMEGANode(for: handle)
        
        guard let nodeName = megaNode.name else {
            throw TransferErrorEntity.couldNotFindNodeByHandle
        }
        
        return downloadEvents(
            of: megaNode,
            named: nodeName,
            to: url,
            filename: filename,
            appdata: appdata,
            startFirst: startFirst
        )
    }
    
    /// The transfer, reported as it runs.
    private func downloadEvents(
        of megaNode: MEGANode,
        named nodeName: String,
        to url: URL,
        filename: String?,
        appdata: String?,
        startFirst: Bool
    ) -> AnyAsyncSequence<TransferEventEntity> {
        let offlineNameString = sdk.escapeFsIncompatible(nodeName, destinationPath: url.path)
        let filePath = url.path + "/" + (offlineNameString ?? nodeName)
        
        return AsyncThrowingStream(TransferEventEntity.self) { continuation in
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
                        
                        // The transfer is what ends this stream. Without a delegate feeding it the download
                        // still runs, but nothing reports back and a caller iterating the sequence waits on
                        // it forever. Built here rather than alongside the stream because the delegate is
                        // not `Sendable` and so cannot be captured by the request's own callback.
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
                        
                        sdk.startDownloadNode(
                            node,
                            localPath: filePath,
                            fileName: name,
                            appData: metaData?.rawValue,
                            startFirst: startFirst,
                            cancelToken: cancelToken.value,
                            collisionCheck: CollisionCheck.fingerprint,
                            collisionResolution: CollisionResolution.newWithN,
                            delegate: transferDelegate
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

/// To be deleted once SDK submodule is updated.
public final class MEGADownloadItemList: NSObject {
    private struct Item {
        let node: MEGANode
        let localPath: String?
        let customName: String?
        let appData: String?
        let startFirst: Bool
        let undelete: Bool
    }

    private var items: [Item] = []

    public var size: Int { items.count }

    public override init() {
        super.init()
    }

    public func add(
        _ node: MEGANode,
        localPath: String?,
        customName: String?,
        appData: String?,
        startFirst: Bool,
        undelete: Bool
    ) {
        items.append(
            Item(
                node: node,
                localPath: localPath,
                customName: customName,
                appData: appData,
                startFirst: startFirst,
                undelete: undelete
            )
        )
    }

    public func node(at index: Int) -> MEGANode? {
        items[safe: index]?.node
    }

    public func localPath(at index: Int) -> String? {
        items[safe: index]?.localPath
    }

    public func customName(at index: Int) -> String? {
        items[safe: index]?.customName
    }

    public func appData(at index: Int) -> String? {
        items[safe: index]?.appData
    }

    public func startFirst(at index: Int) -> Bool {
        items[safe: index]?.startFirst ?? false
    }

    public func undelete(at index: Int) -> Bool {
        items[safe: index]?.undelete ?? false
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

/// To be deleted once SDK submodule is updated.
extension MEGASdk {
    @objc open dynamic func startDownloadBatch(
        withItems items: MEGADownloadItemList,
        cancelToken: MEGACancelToken?,
        collisionCheck: CollisionCheck,
        collisionResolution: CollisionResolution,
        delegate: any MEGATransferDelegate
    ) {
        
    }
}
