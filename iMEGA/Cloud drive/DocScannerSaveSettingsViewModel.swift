import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADomain
import MEGAL10n
import MEGARepo

@MainActor
final class DocScannerSaveSettingsViewModel: ViewModelType {
    var invokeCommand: ((Command) -> Void)?
    
    enum Action: ActionType {
        struct SendToChatRoomModel {
            let docs: [UIImage]?
            let currentFileName: String?
            let originalFileName: String
            let chatRoomId: HandleEntity
        }
        
        struct SendToChatsAndUsersModel {
            let docs: [UIImage]?
            let currentFileName: String?
            let originalFileName: String
            let chats: [ChatListItemEntity]
            let users: [UserEntity]
            let completion: @Sendable (String) -> Void
        }
        
        struct UploadModel {
            let docs: [UIImage]?
            let currentFileName: String?
            let originalFileName: String
            let parentNodeHandle: HandleEntity
        }
        
        case sendScannedDocsToChatRoom(SendToChatRoomModel)
        case sendScannedDocsToChatsAndUsers(SendToChatsAndUsersModel)
        case upload(UploadModel)
    }
    
    enum Command: CommandType {
        case upload(transfers: [CancellableTransfer], collisionEntities: [NameCollisionEntity], collisionType: NameCollisionType)
    }

    struct keys {
        static let docScanExportFileTypeKey = "DocScanExportFileTypeKey"
        static let docScanQualityKey = "DocScanQualityKey"
    }
    
    func dispatch(_ action: Action) {
        switch action {
        case let .sendScannedDocsToChatRoom(model):
            sendScannedDocsToChatRoom(model: model)
        case let .sendScannedDocsToChatsAndUsers(model):
            sendScannedDocsToChatsAndUsers(model: model)
        case let .upload(model):
            upload(model: model)
        }
    }
}

// MARK: - Upload
extension DocScannerSaveSettingsViewModel {
    private func upload(model: Action.UploadModel) {
        Task {
            let paths = await exportScannedDocs(docs: model.docs, currentFileName: model.currentFileName, originalFileName: model.originalFileName)
            let transfers = await buildTransfers(for: paths, parentNodeHandle: model.parentNodeHandle)
            let collisionEntities = transfers.map {
                NameCollisionEntity(
                    parentHandle: $0.parentHandle,
                    name: $0.localFileURL?.lastPathComponent ?? "",
                    isFile: $0.isFile,
                    fileUrl: $0.localFileURL
                )
            }
            invokeCommand?(.upload(transfers: transfers, collisionEntities: collisionEntities, collisionType: .upload))
        }
    }
    
    private func buildTransfers(for paths: [String], parentNodeHandle: HandleEntity) async -> [CancellableTransfer] {
        let metadataUseCase = MetadataUseCase(
            metadataRepository: MetadataRepository(),
            fileSystemRepository: FileSystemRepository.newRepo,
            fileExtensionRepository: FileExtensionRepository(),
            nodeCoordinatesRepository: NodeCoordinatesRepository.newRepo
        )
        
        return await withTaskGroup { taskGroup in
            for path in paths {
                taskGroup.addTask {
                    let appData = await metadataUseCase.formattedCoordinate(forFilePath: path)
                    return CancellableTransfer(
                        handle: .invalid,
                        parentHandle: parentNodeHandle,
                        localFileURL: URL(fileURLWithPath: path),
                        name: nil,
                        appData: appData,
                        priority: false,
                        isFile: true,
                        type: .upload
                    )
                }
            }
            
            return await taskGroup.reduce(into: []) { $0.append($1) }
        }
    }
}

// MARK: - Send to chat room
extension DocScannerSaveSettingsViewModel {
    private func sendScannedDocsToChatRoom(model: Action.SendToChatRoomModel) {
        Task {
            do {
                guard let myChatFilesFolderNode = try await MyChatFilesFolderNodeAccess.shared.loadNode() else {
                    return
                }
                await sendScannedDocsToChatRoom(model: model, parentNode: myChatFilesFolderNode)
            } catch {
                MEGALogWarning("Could not load MyChatFiles target folder due to error \(error.localizedDescription)")
            }
        }
    }
    
    private func sendScannedDocsToChatRoom(model: Action.SendToChatRoomModel, parentNode: MEGANode) async {
        let paths = await exportScannedDocs(docs: model.docs, currentFileName: model.currentFileName, originalFileName: model.originalFileName)
        let pathsAndMetadata = await buildUploadMetadata(paths: paths, chatRoomId: model.chatRoomId)
        await uploadScannedDocs(pathsAndMetadata: pathsAndMetadata, model: model, parentNode: parentNode)
    }
    
    private func uploadScannedDocs(pathsAndMetadata: [(String, String)], model: Action.SendToChatRoomModel, parentNode: MEGANode) async {
        pathsAndMetadata.forEach { (path, metadata) in
            ChatUploader.sharedInstance.upload(
                filepath: path,
                appData: metadata,
                chatRoomId: model.chatRoomId,
                parentNode: parentNode,
                isSourceTemporary: true,
                delegate: MEGAStartUploadTransferDelegate(completion: nil)
            )
        }
    }
}
    
// MARK: - Send to chats and users
extension DocScannerSaveSettingsViewModel {
    private func sendScannedDocsToChatsAndUsers(model: Action.SendToChatsAndUsersModel) {
        Task {
            do {
                guard let myChatFilesFolderNode = try await MyChatFilesFolderNodeAccess.shared.loadNode() else {
                    return
                }
                
                await sendScannedDocsToChatsAndUsers(model: model, parentNode: myChatFilesFolderNode)
            } catch {
                MEGALogWarning("Could not load MyChatFiles target folder due to error \(error.localizedDescription)")
            }
        }
    }
    
    private func sendScannedDocsToChatsAndUsers(model: Action.SendToChatsAndUsersModel, parentNode: MEGANode) async {
        let paths = await exportScannedDocs(docs: model.docs, currentFileName: model.currentFileName, originalFileName: model.originalFileName)
        let pathsAndMetadata = await buildUploadMetadata(paths: paths)
        await uploadScannedDocs(
            pathsAndMetadata: pathsAndMetadata,
            currentFileName: model.currentFileName,
            originalFileName: model.originalFileName,
            parentNode: parentNode,
            chats: model.chats,
            users: model.users,
            completion: model.completion
        )
    }
    
    /// Although there is no await usage inside but `nonisolated async` needed to make it run on background thread from cooperative thread pool
    private nonisolated func uploadScannedDocs(
        pathsAndMetadata: [(String, String)],
        currentFileName: String?,
        originalFileName: String,
        parentNode: MEGANode,
        chats: [ChatListItemEntity],
        users: [UserEntity],
        completion: @Sendable @escaping (String) -> Void
    ) async {
        var completionCounter = 0
        pathsAndMetadata.forEach { (path, metadata) in
            let startUploadTransferDelegate = MEGAStartUploadTransferDelegate { transfer in
                guard let nodeHandle = MEGASdk.shared.node(forHandle: transfer.nodeHandle)?.handle else { return }
                
                chats.forEach { chatRoom in
                    MEGAChatSdk.shared.attachNode(toChat: chatRoom.chatId, node: nodeHandle)
                }
                users.forEach { user in
                    if let chatRoom = MEGAChatSdk.shared.chatRoom(byUser: user.handle) {
                        MEGAChatSdk.shared.attachNode(toChat: chatRoom.chatId, node: nodeHandle)
                    } else {
                        MEGAChatSdk.shared.mnz_createChatRoom(userHandle: user.handle, completion: { (chatRoom) in
                            MEGAChatSdk.shared.attachNode(toChat: chatRoom.chatId, node: nodeHandle)
                        })
                    }
                }
                if completionCounter == pathsAndMetadata.count - 1 {
                    let receiverCount = chats.count + users.count
                    let fileName = currentFileName ?? originalFileName
                    let message = Strings.Localizable.Share.Message.SendToChat.withOneFile(receiverCount).replacingOccurrences(of: "[A]", with: fileName)
                    completion(message)
                }
                completionCounter += 1
            }
            MEGASdk.shared.startUploadForChat(withLocalPath: path, parent: parentNode, appData: metadata, isSourceTemporary: true, fileName: nil, delegate: startUploadTransferDelegate)
        }
    }
}

// MARK: - Utils
extension DocScannerSaveSettingsViewModel {
    private func buildUploadMetadata(paths: [String], chatRoomId: HandleEntity? = nil) async -> [(String, String)] {
        let metadataUseCase = MetadataUseCase(
            metadataRepository: MetadataRepository(),
            fileSystemRepository: FileSystemRepository.newRepo,
            fileExtensionRepository: FileExtensionRepository(),
            nodeCoordinatesRepository: NodeCoordinatesRepository.newRepo
        )
        
        return await withTaskGroup { taskGroup in
            for path in paths {
                taskGroup.addTask {
                    var metadata = ""
                    if let coordinate = await metadataUseCase.formattedCoordinate(forFilePath: path) {
                        metadata += coordinate
                    }
                    
                    if let chatRoomId {
                        metadata = metadata.mnz_appDataToAttach(toChatID: chatRoomId, asVoiceClip: false)
                    }
                    
                    return (path, metadata)
                }
            }
            
            return await taskGroup.reduce(into: []) { $0.append($1) }
        }
    }
    
    /// Although there is no await usage inside but `nonisolated async` needed to make it run on background thread from cooperative thread pool
    private nonisolated func exportScannedDocs(
        docs: [UIImage]?,
        currentFileName: String?,
        originalFileName: String
    ) async -> [String] {
        guard let storedExportFileTypeKey = UserDefaults.standard.string(forKey: keys.docScanExportFileTypeKey) else {
            MEGALogDebug("No stored value found for docScanExportFileTypeKey")
            return []
        }
        let fileType = DocScanExportFileType(rawValue: storedExportFileTypeKey)
        let scanQuality = DocScanQuality(rawValue: UserDefaults.standard.float(forKey: keys.docScanQualityKey)) ?? .best
        var tempPaths: [String] = []
        if fileType == .pdf {
            let pdfDoc = PDFDocument()
            docs?.enumerated().forEach {
                if let shrinkedImageData = $0.element.shrinkedImageData(docScanQuality: scanQuality),
                   let shrinkedImage = UIImage(data: shrinkedImageData),
                   let pdfPage = PDFPage(image: shrinkedImage) {
                    pdfDoc.insert(pdfPage, at: $0.offset)
                } else {
                    MEGALogDebug(String(format: "could not create PdfPage at index %d", $0.offset))
                }
            }
            
            if let data = pdfDoc.dataRepresentation() {
                let fileName = "\(currentFileName ?? originalFileName).pdf"
                let tempPath = (NSTemporaryDirectory() as NSString).appendingPathComponent(fileName)
                do {
                    try data.write(to: URL(fileURLWithPath: tempPath), options: .atomic)
                    tempPaths.append(tempPath)
                } catch {
                    MEGALogDebug("Could not write to file \(tempPath) with error \(error.localizedDescription)")
                }
            } else {
                MEGALogDebug("Cannot convert pdf doc to data representation")
            }
        } else if fileType == .jpg {
            docs?.enumerated().forEach {
                if let data = $0.element.shrinkedImageData(docScanQuality: scanQuality) {
                    let fileName = (docs?.count ?? 1 > 1) ? "\(currentFileName ?? originalFileName) \($0.offset + 1).jpg" : "\(currentFileName ?? originalFileName).jpg"
                    let tempPath = (NSTemporaryDirectory() as NSString).appendingPathComponent(fileName)
                    do {
                        try data.write(to: URL(fileURLWithPath: tempPath), options: .atomic)
                        tempPaths.append(tempPath)
                    } catch {
                        MEGALogDebug("Could not write to file \(tempPath) with error \(error.localizedDescription)")
                    }
                } else {
                    MEGALogDebug("Unable to fetch the stored DocScanQuality")
                }
            }
        }
        return tempPaths
    }
}
