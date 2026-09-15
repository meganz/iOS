public protocol SaveMediaToPhotosUseCaseProtocol: Sendable {
    func saveToPhotos(nodes: [NodeEntity]) async throws
    func saveToPhotosChatNode(handle: HandleEntity, messageId: HandleEntity, chatId: HandleEntity) async throws
    func saveToPhotos(fileLink: FileLinkEntity) async throws
}
        
public struct SaveMediaToPhotosUseCase<T: DownloadFileRepositoryProtocol, U: FileCacheRepositoryProtocol, V: NodeRepositoryProtocol, W: ChatNodeRepositoryProtocol, X: DownloadChatRepositoryProtocol>: SaveMediaToPhotosUseCaseProtocol {
    private let downloadFileRepository: T
    private let fileCacheRepository: U
    private let nodeRepository: V
    private let chatNodeRepository: W
    private let downloadChatRepository: X

    public init(
        downloadFileRepository: T,
        fileCacheRepository: U,
        nodeRepository: V,
        chatNodeRepository: W,
        downloadChatRepository: X
    ) {
        self.downloadFileRepository = downloadFileRepository
        self.fileCacheRepository = fileCacheRepository
        self.nodeRepository = nodeRepository
        self.chatNodeRepository = chatNodeRepository
        self.downloadChatRepository = downloadChatRepository
    }
    
    private func saveToPhotos(node: NodeEntity) async throws {
        do {
            let tempUrl = fileCacheRepository.tempFileURL(for: node)
            try _ = await downloadFileRepository.download(nodeHandle: node.handle, to: tempUrl, metaData: .saveInPhotos)
        } catch TransferErrorEntity.download {
            throw SaveMediaToPhotosErrorEntity.fileDownloadInProgress
        } catch TransferErrorEntity.cancelled {
            throw SaveMediaToPhotosErrorEntity.cancelled
        } catch {
            throw SaveMediaToPhotosErrorEntity.downloadFailed
        }
    }
    
    public func saveToPhotos(nodes: [NodeEntity]) async throws {
        if BatchDownloadFeatureFlag.isEnabled {
            try await saveToPhotosInBatch(nodes: nodes)
        } else {
            try await legacySaveToPhotos(nodes: nodes)
        }
    }
    
    private func saveToPhotosInBatch(nodes: [NodeEntity]) async throws {
        let batch = nodes.map {
            DownloadBatchItemEntity(
                source: .node($0.handle),
                destination: .folder(fileCacheRepository.base64HandleTempFolder(for: $0.base64Handle)),
                appData: TransferMetaDataEntity.saveInPhotos.rawValue,
                startFirst: true
            )
        }
        do {
            try await downloadFileRepository.download(batch: batch)
        } catch let error as TransferErrorEntity {
            if error == .cancelled {
                throw SaveMediaToPhotosErrorEntity.cancelled
            } else {
                throw SaveMediaToPhotosErrorEntity.downloadFailed
            }
        }
    }
    
    private func legacySaveToPhotos(nodes: [NodeEntity]) async throws {
        try await withThrowingTaskGroup(of: Void.self) { taskGroup in
            guard taskGroup.isCancelled == false else {
                throw TransferErrorEntity.generic
            }
            
            nodes.forEach { node in
                taskGroup.addTask {
                    try await saveToPhotos(node: node)
                }
            }
            
            try await taskGroup.waitForAll()
        }
    }
    
    public func saveToPhotosChatNode(handle: HandleEntity, messageId: HandleEntity, chatId: HandleEntity) async throws {
        if BatchDownloadFeatureFlag.isEnabled {
            try await saveToPhotosChatNodeInBatch(handle: handle, messageId: messageId, chatId: chatId)
        } else {
            try await legacySaveToPhotosChatNode(handle: handle, messageId: messageId, chatId: chatId)
        }
    }
    
    private func saveToPhotosChatNodeInBatch(handle: HandleEntity, messageId: HandleEntity, chatId: HandleEntity) async throws {
        guard let node = await chatNodeRepository.chatNode(handle: handle, messageId: messageId, chatId: chatId) else {
            throw SaveMediaToPhotosErrorEntity.nodeNotFound
        }
        let batchItem = DownloadBatchItemEntity(
            source: .chatNode(handle: handle, messageId: messageId, chatId: chatId),
            destination: .folder(fileCacheRepository.base64HandleTempFolder(for: node.base64Handle)),
            appData: TransferMetaDataEntity.saveInPhotos.rawValue,
            startFirst: true
        )
        
        do {
            try await downloadFileRepository.download(batch: [batchItem])
        } catch let error as TransferErrorEntity {
            if error == .cancelled {
                throw SaveMediaToPhotosErrorEntity.cancelled
            } else {
                throw SaveMediaToPhotosErrorEntity.downloadFailed
            }
        }
    }
    
    private func legacySaveToPhotosChatNode(handle: HandleEntity, messageId: HandleEntity, chatId: HandleEntity) async throws {
        guard let node = await chatNodeRepository.chatNode(handle: handle, messageId: messageId, chatId: chatId) else {
            throw SaveMediaToPhotosErrorEntity.nodeNotFound
        }
        
        let tempUrl = fileCacheRepository.tempFileURL(for: node)
        do {
            _ = try await downloadChatRepository.downloadChat(nodeHandle: handle, messageId: messageId, chatId: chatId, to: tempUrl, metaData: .saveInPhotos)
            return
        } catch let error as TransferErrorEntity {
            if error == .cancelled {
                throw SaveMediaToPhotosErrorEntity.cancelled
            } else {
                throw SaveMediaToPhotosErrorEntity.downloadFailed
            }
        }
    }
    
    public func saveToPhotos(fileLink: FileLinkEntity) async throws {
        let node: NodeEntity
        do {
            node = try await nodeRepository.nodeFor(fileLink: fileLink)
        } catch {
            throw SaveMediaToPhotosErrorEntity.nodeNotFound
        }
        
        do {
            if BatchDownloadFeatureFlag.isEnabled {
                try await saveToPhotosInBatch(fileLink: fileLink, fileLinkNode: node)
            } else {
                try await legacySaveToPhotos(fileLink: fileLink, fileLinkNode: node)
            }
        } catch let error as TransferErrorEntity {
            if error == .cancelled {
                throw SaveMediaToPhotosErrorEntity.cancelled
            } else {
                throw SaveMediaToPhotosErrorEntity.downloadFailed
            }
        }
    }
    
    private func saveToPhotosInBatch(fileLink: FileLinkEntity, fileLinkNode: NodeEntity) async throws {
        let batchItem = DownloadBatchItemEntity(
            source: .fileLink(fileLink),
            destination: .folder(fileCacheRepository.base64HandleTempFolder(for: fileLinkNode.base64Handle)),
            appData: TransferMetaDataEntity.saveInPhotos.rawValue,
            startFirst: true
        )
        
        try await downloadFileRepository.download(batch: [batchItem])
    }
    
    private func legacySaveToPhotos(fileLink: FileLinkEntity, fileLinkNode: NodeEntity) async throws {
        _ = try downloadFileRepository.downloadFileLink(
            fileLink,
            named: fileLinkNode.name,
            to: fileCacheRepository.base64HandleTempFolder(for: fileLinkNode.base64Handle),
            metaData: .saveInPhotos,
            startFirst: true
        )
    }
}
