import Foundation

// MARK: - Use case protocol -
public protocol ExportFileNodeUseCaseProtocol {
    func export(node: NodeEntity, completion: @escaping (Result<URL, ExportFileErrorEntity>) -> Void)
    func export(nodes: [NodeEntity], completion: @escaping ([URL]) -> Void)
}

public protocol ExportFileChatMessageUseCaseProtocol {
    func export(messages: [ChatMessageEntity], chatId: HandleEntity, completion:  @escaping ([URL]) -> Void)
    func exportNode(_ node: NodeEntity, messageId: HandleEntity, chatId: HandleEntity, completion: @escaping (Result<URL, ExportFileErrorEntity>) -> Void)
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
                                M: MediaUseCaseProtocol> {
    private let downloadFileRepository: T
    private let offlineFilesRepository: U
    private let fileCacheRepository: V
    private let exportChatMessagesRepository: W
    private let importNodeRepository: X
    private let thumbnailRepository: R
    private let fileSystemRepository: F
    private let mediaUseCase: M
    private let megaHandleRepository: Z
    
    public init(downloadFileRepository: T,
                offlineFilesRepository: U,
                fileCacheRepository: V,
                thumbnailRepository: R,
                fileSystemRepository: F,
                exportChatMessagesRepository: W,
                importNodeRepository: X,
                megaHandleRepository: Z,
                mediaUseCase: M = MediaUseCase()) {
        self.downloadFileRepository = downloadFileRepository
        self.offlineFilesRepository = offlineFilesRepository
        self.fileCacheRepository = fileCacheRepository
        self.thumbnailRepository = thumbnailRepository
        self.fileSystemRepository = fileSystemRepository
        self.exportChatMessagesRepository = exportChatMessagesRepository
        self.importNodeRepository = importNodeRepository
        self.megaHandleRepository = megaHandleRepository
        self.mediaUseCase = mediaUseCase
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
        guard let offlinePath = offlineFilesRepository.offlineFile(for: base64Handle)?.localPath else { return nil }
        return URL(fileURLWithPath: offlineFilesRepository.offlineURL?.path.append(pathComponent: offlinePath) ?? "")
    }
    
    private func processDownloadThenShareResult(result: Result<TransferEntity, TransferErrorEntity>, completion: @escaping (Result<URL, ExportFileErrorEntity>) -> Void) {
        switch result {
        case .success(let transferEntity):
            guard let path = transferEntity.path else { return }
            let url = URL(fileURLWithPath: path)
            completion(.success(url))
            
        case .failure(_):
            completion(.failure(.downloadFailed))
        }
    }
    
    private func importNodeToDownload(_ node: NodeEntity, messageId: HandleEntity, chatId: HandleEntity, completion: @escaping (Result<URL, ExportFileErrorEntity>) -> Void) {
        importNodeRepository.importChatNode(node, messageId:messageId, chatId:chatId) { result in
            switch result {
            case .success(let node):
                downloadNode(node, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func downloadNode(_ node: NodeEntity, completion: @escaping (Result<URL, ExportFileErrorEntity>) -> Void) {
        if fileSystemRepository.systemVolumeAvailability() < node.size {
            completion(.failure(.notEnoughSpace))
            return
        }
        let url = mediaUseCase.isImage(node.name) ? fileCacheRepository.cachedOriginalImageURL(for: node) : fileCacheRepository.tempFileURL(for: node)
        downloadFileRepository.download(nodeHandle: node.handle, to: url, metaData: .exportFile) { result in
            processDownloadThenShareResult(result: result, completion: completion)
        }
    }
}

// MARK: - ExportFileNodeUseCaseProtocol implementation -
extension ExportFileUseCase: ExportFileNodeUseCaseProtocol {
    public func export(node: NodeEntity, completion: @escaping (Result<URL, ExportFileErrorEntity>) -> Void) {
        if let nodeUrl = nodeUrl(node) {
            completion(.success(nodeUrl))
        } else {
            downloadNode(node, completion: completion)
        }
    }
    
    public func export(nodes: [NodeEntity], completion: @escaping ([URL]) -> Void) {
        var urlsArray = [URL]()
        let myGroup = DispatchGroup()
        
        for node in nodes {
            myGroup.enter()
            
            export(node: node) { result in
                switch result {
                case .success(let url):
                    urlsArray.append(url)
                case .failure(let error):
                    print("Failed to export node with error: \(error)")
                }
                myGroup.leave()
            }
        }
        
        myGroup.notify(queue: .main) {
            completion(urlsArray)
        }
    }
}

// MARK: - ExportFileChatMessageUseCaseProtocol implementation -
extension ExportFileUseCase: ExportFileChatMessageUseCaseProtocol {
    private func export(message: ChatMessageEntity, chatId: HandleEntity, completion: @escaping (Result<URL, ExportFileErrorEntity>) -> Void) {
        switch message.type {
        case .normal, .containsMeta:
            if let url = exportChatMessagesRepository.exportText(message: message) {
                completion(.success(url))
            } else {
                completion(.failure(.failedToExportText))
            }
            
        case .contact:
            guard let handle = message.peers.first?.handle, let base64Handle = megaHandleRepository.base64Handle(forUserHandle: handle) else {
                completion(.failure(.failedToCreateContact))
                return
            }
            let avatarUrl = thumbnailRepository.cachedThumbnailURL(for: base64Handle, type: .thumbnail)
            if let contactUrl = exportChatMessagesRepository.exportContact(message: message, contactAvatarImage: fileSystemRepository.fileExists(at: avatarUrl) ? avatarUrl.path : nil) {
                completion(.success(contactUrl))
            } else {
                completion(.failure(.failedToCreateContact))
            }
            
        case .attachment, .voiceClip:
            guard let node = message.nodes?.first else {
                completion(.failure(.nonExportableMessage))
                return
            }
            exportNode(node, messageId:message.messageId, chatId: chatId, completion: completion)
            
        default:
            print("Failed to export a non compatible message type \(message.type)")
            completion(.failure(.nonExportableMessage))
        }
    }
    
    public func export(messages: [ChatMessageEntity], chatId: HandleEntity, completion: @escaping ([URL]) -> Void) {
        var urlsArray = [URL]()
        let myGroup = DispatchGroup()
        
        for message in messages {
            myGroup.enter()
            
            export(message: message, chatId: chatId) { result in
                switch result {
                case .success(let url):
                    urlsArray.append(url)
                case .failure(let error):
                    print("Failed to export a non compatible message type \(message.type) with error: \(error)")
                }
                myGroup.leave()
            }
        }
        
        myGroup.notify(queue: .main) {
            completion(urlsArray)
        }
    }
    
    public func exportNode(_ node: NodeEntity, messageId: HandleEntity, chatId: HandleEntity, completion: @escaping (Result<URL, ExportFileErrorEntity>) -> Void) {
        if let nodeUrl = nodeUrl(node) {
            completion(.success(nodeUrl))
        } else {
            importNodeToDownload(node, messageId: messageId, chatId: chatId, completion: completion)
        }
    }
}
