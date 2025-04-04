import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADomain
import MEGAL10n
 
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
    
    /// This serial queue is used to to avoid app hangs which potentially happens in the scanned doc processing logic below
    /// 1. `MyChatFilesFolderNodeAccess` is used. Its implementation uses Semaphore which is unsafe and is not recommended to use
    /// in Swift Concurrency. So this serial queue is used to execute it and then bridge to Swift Concurrency using withCheckedContinuation.
    /// 2. Paths, chats, users are synchornously looped through, these operation could be time consuming so we need to make it off main thread.
    /// While using nonisolated is an option but it requires big refactor on the existing logic which makes this MR less focused, so put them inside this serial queue is prefered.
    /// Further refactor / logic improvements would be in separate MRs
    private let scannedDocsProcessingQueue = DispatchQueue(label: "com.mega.DocScannerSaveSettingsViewModel.scannedDocsProcessingQueue")

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
    
    private func upload(model: Action.UploadModel) {
        let paths = exportScannedDocs(docs: model.docs, currentFileName: model.currentFileName, originalFileName: model.originalFileName)
        let transfers = paths.map {
            CancellableTransfer(
                handle: .invalid,
                parentHandle: model.parentNodeHandle,
                localFileURL: URL(fileURLWithPath: $0),
                name: nil,
                appData: NSString().mnz_appData(toSaveCoordinates: $0.mnz_coordinatesOfPhotoOrVideo() ?? ""),
                priority: false,
                isFile: true,
                type: .upload
            )
        }
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
}

// MARK: - Privates
extension DocScannerSaveSettingsViewModel {
    private func sendScannedDocsToChatRoom(model: Action.SendToChatRoomModel, parentNode: MEGANode) async {
        await withCheckedContinuation { continuation in
            scannedDocsProcessingQueue.async { [weak self] in
                guard let self else {
                    continuation.resume()
                    return
                }
                let paths = exportScannedDocs(docs: model.docs, currentFileName: model.currentFileName, originalFileName: model.originalFileName)
                uploadScannedDocs(paths: paths, chatRoomId: model.chatRoomId, parentNode: parentNode)
                continuation.resume()
            }
        }
    }
    
    private func sendScannedDocsToChatsAndUsers(model: Action.SendToChatsAndUsersModel, parentNode: MEGANode) async {
        await withCheckedContinuation { continuation in
            scannedDocsProcessingQueue.async { [weak self] in
                guard let self else {
                    continuation.resume()
                    return
                }
                
                let paths = exportScannedDocs(docs: model.docs, currentFileName: model.currentFileName, originalFileName: model.originalFileName)
                uploadScannedDocs(
                    paths: paths,
                    currentFileName: model.currentFileName,
                    originalFileName: model.originalFileName,
                    parentNode: parentNode,
                    chats: model.chats,
                    users: model.users,
                    completion: model.completion
                )
                continuation.resume()
            }
        }
    }
    
    private nonisolated func uploadScannedDocs(paths: [String], chatRoomId: HandleEntity, parentNode: MEGANode) {
        paths.forEach { (path) in
            var appData = NSString().mnz_appData(toSaveCoordinates: path.mnz_coordinatesOfPhotoOrVideo() ?? "")
            appData = ((appData) as NSString).mnz_appDataToAttach(toChatID: chatRoomId, asVoiceClip: false)
            ChatUploader.sharedInstance.upload(
                filepath: path,
                appData: appData,
                chatRoomId: chatRoomId,
                parentNode: parentNode,
                isSourceTemporary: true,
                delegate: MEGAStartUploadTransferDelegate(completion: nil)
            )
        }
    }
    
    private nonisolated func uploadScannedDocs(
        paths: [String],
        currentFileName: String?,
        originalFileName: String,
        parentNode: MEGANode,
        chats: [ChatListItemEntity],
        users: [UserEntity],
        completion: @Sendable @escaping (String) -> Void
    ) {
        var completionCounter = 0
        paths.forEach { (path) in
            let appData = NSString().mnz_appData(toSaveCoordinates: path.mnz_coordinatesOfPhotoOrVideo() ?? "")
            let startUploadTransferDelegate = MEGAStartUploadTransferDelegate { (transfer) in
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
                if completionCounter == paths.count - 1 {
                    let receiverCount = chats.count + users.count
                    let fileName = currentFileName ?? originalFileName
                    let message = Strings.Localizable.Share.Message.SendToChat.withOneFile(receiverCount).replacingOccurrences(of: "[A]", with: fileName)
                    completion(message)
                }
                completionCounter += 1
            }
            MEGASdk.shared.startUploadForChat(withLocalPath: path, parent: parentNode, appData: appData, isSourceTemporary: true, fileName: nil, delegate: startUploadTransferDelegate)
        }
    }
    
    private nonisolated func exportScannedDocs(
        docs: [UIImage]?,
        currentFileName: String?,
        originalFileName: String
    ) -> [String] {
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
