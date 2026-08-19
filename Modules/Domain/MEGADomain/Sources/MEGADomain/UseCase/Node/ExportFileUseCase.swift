import Foundation

// MARK: - Use case protocol -
public protocol ExportFileNodeUseCaseProtocol: Sendable {
    func export(node: NodeEntity) async throws -> URL
    /// Exports a selection of nodes, reporting how much of it arrived.
    func export(nodes: [NodeEntity]) async throws -> ExportedSelectionEntity
    /// Exports a folder node, reporting how much of it arrived.
    func exportFolder(_ node: NodeEntity) async throws -> ExportedNodeEntity
}

public protocol ExportFileChatMessageUseCaseProtocol: Sendable {
    func export(messages: [ChatMessageEntity], chatId: HandleEntity) async -> [URL]
    func exportNode(_ node: NodeEntity, messageId: HandleEntity, chatId: HandleEntity) async throws -> URL
}

public typealias ExportFileUseCaseProtocol = ExportFileNodeUseCaseProtocol & ExportFileChatMessageUseCaseProtocol

// MARK: - Use case implementation -
public struct ExportFileUseCase<T: DownloadFileRepositoryProtocol,
                                U: OfflineFilesRepositoryProtocol,
                                V: FileCacheRepositoryProtocol,
                                R: ThumbnailRepositoryProtocol,
                                F: FileSystemRepositoryProtocol,
                                W: ExportChatMessagesRepositoryProtocol,
                                X: ImportNodeRepositoryProtocol,
                                Z: MEGAHandleRepositoryProtocol,
                                M: MediaUseCaseProtocol,
                                G: OfflineFileFetcherRepositoryProtocol,
                                H: UserStoreRepositoryProtocol>: Sendable {
    private let downloadFileRepository: T
    private let offlineFilesRepository: U
    private let fileCacheRepository: V
    private let exportChatMessagesRepository: W
    private let importNodeRepository: X
    private let thumbnailRepository: R
    private let fileSystemRepository: F
    private let mediaUseCase: M
    private let megaHandleRepository: Z
    private let offlineFileFetcherRepository: G
    private let userStoreRepository: H
    private let handsOverIncompleteFolders: Bool
    
    public init(
        downloadFileRepository: T,
        offlineFilesRepository: U,
        fileCacheRepository: V,
        thumbnailRepository: R,
        fileSystemRepository: F,
        exportChatMessagesRepository: W,
        importNodeRepository: X,
        megaHandleRepository: Z,
        mediaUseCase: M,
        offlineFileFetcherRepository: G,
        userStoreRepository: H,
        handsOverIncompleteFolders: Bool = false
    ) {
        self.downloadFileRepository = downloadFileRepository
        self.offlineFilesRepository = offlineFilesRepository
        self.fileCacheRepository = fileCacheRepository
        self.thumbnailRepository = thumbnailRepository
        self.fileSystemRepository = fileSystemRepository
        self.exportChatMessagesRepository = exportChatMessagesRepository
        self.importNodeRepository = importNodeRepository
        self.megaHandleRepository = megaHandleRepository
        self.mediaUseCase = mediaUseCase
        self.offlineFileFetcherRepository = offlineFileFetcherRepository
        self.userStoreRepository = userStoreRepository
        self.handsOverIncompleteFolders = handsOverIncompleteFolders
    }
    
    // MARK: - Private
    @MainActor
    private func nodeUrl(_ node: NodeEntity) -> URL? {
        if let offlineUrl = offlineUrl(for: node.base64Handle) {
            return offlineUrl
        } else if mediaUseCase.isImage(node.name), let imageUrl = fileCacheRepository.existingOriginalImageURL(for: node) {
            return imageUrl
        } else if let fileUrl = fileCacheRepository.existingTempFileURL(for: node) {
            // Safe for a folder as well as a file: neither takes its final name until it is whole, so what
            // is found here is never a download still in progress. See `downloadFolder(_:)`.
            return fileUrl
        } else {
            return nil
        }
    }

    /// An offline record can outlive the copy it points at: the store it comes from and the copy itself sit
    /// in different containers, so reinstalling leaves the record behind with nothing under it. Both cache
    /// branches in `nodeUrl(_:)` already check for the file, and without the same check here a stale record
    /// makes the export skip its download and hand back a path with nothing at it.
    private func offlineUrl(for base64Handle: Base64HandleEntity) -> URL? {
        guard let offlinePath = offlineFileFetcherRepository.offlineFile(for: base64Handle)?.localPath else { return nil }

        let offlineUrl = URL(fileURLWithPath: offlineFilesRepository.offlineURL?.path.append(pathComponent: offlinePath) ?? "")
        return fileSystemRepository.fileExists(at: offlineUrl) ? offlineUrl : nil
    }
    
    private func importNodeToDownload(_ node: NodeEntity, messageId: HandleEntity, chatId: HandleEntity) async throws -> URL {
        let node = try await importNodeRepository.importChatNode(node, messageId: messageId, chatId: chatId)
        return try await downloadNode(node)
    }

    /// A folder short of some of its files still comes back as a URL here rather than throwing: this path
    /// deals in nodes, so the counts have nowhere to go, and handing over what arrived beats discarding it.
    /// Callers that need to say what is missing ask for `exportFolder(_:)` instead.
    private func downloadNode(_ node: NodeEntity) async throws -> URL {
        guard node.isFile else {
            guard let url = try await downloadFolder(node).url else {
                throw ExportFileErrorEntity.downloadFailed
            }
            return url
        }
        return try await downloadFile(node)
    }

    private func downloadFile(_ node: NodeEntity) async throws -> URL {
        let url = mediaUseCase.isImage(node.name)
            ? fileCacheRepository.cachedOriginalImageURL(for: node)
            : fileCacheRepository.tempFileURL(for: node)
        do {
            let transferEntity = try await downloadFileRepository.download(nodeHandle: node.handle, to: url, metaData: .exportFile)
            guard let path = transferEntity.path else {
                throw ExportFileErrorEntity.downloadFailed
            }
            return URL(fileURLWithPath: path)
        } catch {
            throw ExportFileErrorEntity.downloadFailed
        }
    }

    /// Downloads a folder into a staging directory and moves it where it belongs once it is whole, so that
    /// finding the final directory always means a finished download.
    ///
    /// The SDK already does this for a file — it writes under a temporary leaf name and takes the real one
    /// on completion — but it builds a folder's directory tree under the final name before downloading
    /// anything into it, which leaves a half-filled tree indistinguishable from a finished one.
    ///
    /// A folder that came back short stays in staging and is handed over from there: it is worth offering,
    /// but moving it into place would make the next export mistake it for a finished download.
    private func downloadFolder(_ node: NodeEntity) async throws -> ExportedNodeEntity {
        let destinationURL = fileCacheRepository.tempFileURL(for: node)
        let stagingURL = fileCacheRepository.stagingTempFileURL(for: node)
        let stagingFolderURL = fileCacheRepository.stagingTempFolder(for: node)

        // Whatever being killed mid download left behind: the SDK would otherwise download alongside it
        // under a deduplicated name, and the move below would carry the older tree over instead. Only the
        // copy is cleared, not the directory holding it, which the download still needs to exist.
        try? await fileSystemRepository.removeItem(at: stagingURL)

        let result: FolderDownloadResultEntity
        do {
            result = try await downloadFileRepository.downloadFolder(
                nodeHandle: node.handle,
                to: stagingURL,
                metaData: .exportFile
            )
        } catch TransferErrorEntity.cancelled {
            try? await fileSystemRepository.removeItem(at: stagingFolderURL)
            // The user stopped it themselves, so this leaves rather than reporting a shortfall back at them.
            throw ExportFileErrorEntity.downloadFailed
        } catch {
            try? await fileSystemRepository.removeItem(at: stagingFolderURL)
            // The transfer never ran, so there are no file counts to report and the caller is left to speak
            // about the folder itself.
            return ExportedNodeEntity(url: nil, fileCount: 0, downloadedFileCount: 0)
        }

        guard result.isSuccess else {
            guard handsOverIncompleteFolders, result.downloadedFileCount > 0 else {
                // Counted as having delivered nothing, because that is what the caller is left with once
                // the partial tree is gone.
                try? await fileSystemRepository.removeItem(at: stagingFolderURL)
                return ExportedNodeEntity(url: nil, fileCount: result.fileCount, downloadedFileCount: 0)
            }
            return ExportedNodeEntity(
                url: stagingURL,
                fileCount: result.fileCount,
                downloadedFileCount: result.downloadedFileCount
            )
        }

        // Handed over from staging if the move fails: the tree is whole and merely in the wrong place, and
        // the only cost is that the next export downloads it again instead of finding it in the cache. The
        // staging directory has to stay for the same reason.
        guard fileSystemRepository.moveFile(at: stagingURL, to: destinationURL) else {
            return ExportedNodeEntity(
                url: stagingURL,
                fileCount: result.fileCount,
                downloadedFileCount: result.downloadedFileCount
            )
        }
        // The whole staging directory, not the copy inside it: a move that happened leaves that directory
        // empty, and one would otherwise pile up for every folder ever exported. It also covers the move
        // reporting success without moving anything, which is what it does when the destination is already
        // there — another export having finished the same folder first, whose copy is as good as ours.
        try? await fileSystemRepository.removeItem(at: stagingFolderURL)

        return ExportedNodeEntity(
            url: destinationURL,
            fileCount: result.fileCount,
            downloadedFileCount: result.downloadedFileCount
        )
    }
}

// MARK: - ExportFileNodeUseCaseProtocol implementation -
extension ExportFileUseCase: ExportFileNodeUseCaseProtocol {
    public func export(node: NodeEntity) async throws -> URL {
        if let nodeUrl = await nodeUrl(node) {
            return nodeUrl
        } else {
            return try await downloadNode(node)
        }
    }
    
    public func exportFolder(_ node: NodeEntity) async throws -> ExportedNodeEntity {
        if let nodeUrl = await nodeUrl(node) {
            // A cached copy is only ever a finished one, so what is in it is both everything that was asked
            // for and everything that arrived. Counted rather than left at zero, because a selection reports in files
            let fileCount = await fileSystemRepository.fileCount(at: nodeUrl)
            return ExportedNodeEntity(url: nodeUrl, fileCount: fileCount, downloadedFileCount: fileCount)
        }
        return try await downloadFolder(node)
    }

    public func export(nodes: [NodeEntity]) async throws -> ExportedSelectionEntity {
        await withTaskGroup(of: ExportedNodeEntity.self) { group in
            for node in nodes {
                group.addTask { await exportCounted(node) }
            }

            var selection = ExportedSelectionEntity.nothing
            for await node in group {
                selection = selection.adding(node)
            }
            return selection
        }
    }

    /// What one node of a selection amounts to, so that a folder is counted by the files inside it while a
    /// file counts as itself.
    private func exportCounted(_ node: NodeEntity) async -> ExportedNodeEntity {
        do {
            guard node.isFile else { return try await exportFolder(node) }
            return ExportedNodeEntity(url: try await export(node: node), fileCount: 1, downloadedFileCount: 1)
        } catch {
            print("Failed to export node with error: \(error)")
            // No count came back either, so this leaves the node speaking for itself — see
            // `ExportedNodeEntity.requestedFileCount`.
            return ExportedNodeEntity(url: nil, fileCount: 0, downloadedFileCount: 0)
        }
    }
}

// MARK: - ExportFileChatMessageUseCaseProtocol implementation -
extension ExportFileUseCase: ExportFileChatMessageUseCaseProtocol {
    private func export(message: ChatMessageEntity, chatId: HandleEntity) async throws -> URL {
        switch message.type {
        case .normal, .containsMeta:
            if let url = exportChatMessagesRepository.exportText(message: message) {
                return url
            } else {
                throw ExportFileErrorEntity.failedToExportText
            }
            
        case .contact:
            guard let handle = message.peers.first?.handle, let base64Handle = megaHandleRepository.base64Handle(forUserHandle: handle) else {
                throw ExportFileErrorEntity.failedToCreateContact
            }
            let avatarUrl = thumbnailRepository.generateCachingURL(for: base64Handle, type: .thumbnail)
            let contactAvatarImage = fileSystemRepository.fileExists(at: avatarUrl) ? avatarUrl.path : nil
            let firstName = userStoreRepository.userFirstName(withHandle: handle)
            let lastName = userStoreRepository.userLastName(withHandle: handle)
            if let contactUrl = exportChatMessagesRepository.exportContact(
                message: message,
                contactAvatarImage: contactAvatarImage,
                userFirstName: firstName,
                userLastName: lastName
            ) {
                return contactUrl
            } else {
                throw ExportFileErrorEntity.failedToCreateContact
            }
            
        case .attachment, .voiceClip:
            guard let node = message.nodes?.first else {
                throw ExportFileErrorEntity.nonExportableMessage
            }
            return try await exportNode(node, messageId: message.messageId, chatId: chatId)
            
        default:
            print("Failed to export a non compatible message type \(message.type)")
            throw ExportFileErrorEntity.nonExportableMessage
        }
    }
    
    public func export(messages: [ChatMessageEntity], chatId: HandleEntity) async -> [URL] {
        var urlsArray = [URL]()
        return await withTaskGroup(of: URL?.self) { group in
            for message in messages {
                group.addTask {
                    do {
                        return try await export(message: message, chatId: chatId)
                    } catch {
                        print("Failed to export a non compatible message type \(message.type) with error: \(error)")
                        return nil
                    }
                }
            }
            
            for await result in group.compacted() {
                urlsArray.append(result)
            }
            return urlsArray
        }
    }
    
    public func exportNode(_ node: NodeEntity, messageId: HandleEntity, chatId: HandleEntity) async throws -> URL {
        if let nodeUrl = await nodeUrl(node) {
            return nodeUrl
        } else {
            return try await importNodeToDownload(node, messageId: messageId, chatId: chatId)
        }
    }
}
