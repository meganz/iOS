import Foundation

// MARK: - Use case protocol -

public protocol ExportFileNodeUseCaseProtocol {
    func export(node: NodeEntity) async throws -> URL
    func export(nodes: [NodeEntity]) async throws -> [URL]
}

public protocol ExportFileChatMessageUseCaseProtocol {
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
        userStoreRepository: H
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
    }
    
    // MARK: - Private
    private func nodeUrl(_ node: NodeEntity) -> URL? {
        if let offlineUrl = offlineUrl(for: node.base64Handle) {
            return offlineUrl
        } else if mediaUseCase.isImage(node.name), let imageUrl = fileCacheRepository.existingOriginalImageURL(for: node) {
            return imageUrl
        } else if let fileUrl = fileCacheRepository.existingTempFileURL(for: node) {
            return fileUrl
        } else {
            return nil
        }
    }
    
    private func offlineUrl(for base64Handle: Base64HandleEntity) -> URL? {
        guard let offlinePath = offlineFileFetcherRepository.offlineFile(for: base64Handle)?.localPath else { return nil }
        return URL(fileURLWithPath: offlineFilesRepository.offlineURL?.path.append(pathComponent: offlinePath) ?? "")
    }
    
    private func importNodeToDownload(_ node: NodeEntity, messageId: HandleEntity, chatId: HandleEntity) async throws -> URL {
        let node = try await importNodeRepository.importChatNode(node, messageId: messageId, chatId: chatId)
        return try await downloadNode(node)
    }

    private func downloadNode(_ node: NodeEntity) async throws -> URL {
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
}

// MARK: - ExportFileNodeUseCaseProtocol implementation -
extension ExportFileUseCase: ExportFileNodeUseCaseProtocol {
    public func export(node: NodeEntity) async throws -> URL {
        if let nodeUrl = nodeUrl(node) {
            return nodeUrl
        } else {
            return try await downloadNode(node)
        }
    }
    
    public func export(nodes: [NodeEntity]) async throws -> [URL] {
        var urlsArray = [URL]()
        return await withTaskGroup(of: URL?.self) { group in
            for node in nodes {
                group.addTask {
                    do {
                        return try await export(node: node)
                    } catch {
                        print("Failed to export node with error: \(error)")
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
        if let nodeUrl = nodeUrl(node) {
            return nodeUrl
        } else {
            return try await importNodeToDownload(node, messageId: messageId, chatId: chatId)
        }
    }
}
