import ChatRepo
import MEGAAppSDKRepo
import MEGADomain
import MEGARepo

protocol ChatUploaderProtocol {
    func upload(image: UIImage, chatRoomId: UInt64) async
    func upload(
        filepath: String,
        appData: String,
        chatRoomId: UInt64,
        parentNode: MEGANode,
        isSourceTemporary: Bool,
        delegate: MEGAStartUploadTransferDelegate
    )
}

final class ChatUploader: NSObject, ChatUploaderProtocol {
    static let sharedInstance = ChatUploader()
    
    private let store = MEGAStore.shareInstance()
    
    private var isDatabaseCleanupTaskCompleted: Bool?
    private let uploaderQueue = DispatchQueue(label: "ChatUploaderQueue")

    private override init() { super.init() }
    
    private var metadataUseCase: some MetadataUseCaseProtocol {
        MetadataUseCase(
            metadataRepository: MetadataRepository(),
            fileSystemRepository: FileSystemRepository.sharedRepo,
            fileExtensionRepository: FileExtensionRepository(),
            nodeCoordinatesRepository: NodeCoordinatesRepository.newRepo
        )
    }
    
    @objc func setup() {
        isDatabaseCleanupTaskCompleted = false
        MEGASdk.shared.add(self)
    }
    
    func upload(image: UIImage, chatRoomId: UInt64) async {
        do {
            guard let myChatFilesFolderNode = try await MyChatFilesFolderNodeAccess.shared.loadNode() else {
                MEGALogDebug("Could not load MyChatFiles target folder")
                return
            }
            
            guard let data = image.jpegData(compressionQuality: CGFloat(0.7)) else {
                return
            }
            
            let fileName = "\(NSDate().mnz_formattedDefaultNameForMedia()).jpg"
            let tempPath = (NSTemporaryDirectory() as NSString).appendingPathComponent(fileName)
            do {
                try data.write(to: URL(fileURLWithPath: tempPath), options: .atomic)
                var appData = ""
                appData = appData.mnz_appDataToAttach(toChatID: chatRoomId, asVoiceClip: false)
                
                if let formattedCoordinate = await metadataUseCase.formattedCoordinate(forFilePath: tempPath) {
                    appData += formattedCoordinate
                }
                
                ChatUploader.sharedInstance.upload(filepath: tempPath,
                                                   appData: appData,
                                                   chatRoomId: chatRoomId,
                                                   parentNode: myChatFilesFolderNode,
                                                   isSourceTemporary: false,
                                                   delegate: MEGAStartUploadTransferDelegate(completion: nil))
                
            } catch {
                MEGALogDebug("Could not write to file \(tempPath) with error \(error.localizedDescription)")
            }
        } catch {
            MEGALogDebug("Could not load MyChatFiles target folder due to error \(error.localizedDescription)")
        }
    }
    
    func upload(filepath: String,
                appData: String,
                chatRoomId: UInt64,
                parentNode: MEGANode,
                isSourceTemporary: Bool,
                delegate: MEGAStartUploadTransferDelegate) {
        
        MEGALogInfo("[ChatUploader] uploading File path \(filepath)")
        cleanupDatabaseIfRequired()
        guard let context = store.stack.newBackgroundContext() else { return }
        
        context.performAndWait {
            MEGALogInfo("[ChatUploader] inserted new entry File path \(filepath)")
            // insert into database only if the duplicate path does not exsist - "allowDuplicateFilePath" parameter
            self.store.insertChatUploadTransfer(withFilepath: filepath,
                                                chatRoomId: String(chatRoomId),
                                                transferTag: nil,
                                                allowDuplicateFilePath: false,
                                                context: context)
            
            MEGALogInfo("[ChatUploader] SDK upload started for File path \(filepath)")
            MEGASdk.shared.startUploadForChat(withLocalPath: filepath,
                                              parent: parentNode,
                                              appData: appData,
                                              isSourceTemporary: isSourceTemporary,
                                              fileName: nil,
                                              delegate: delegate)
        }
    }
    
    // MARK: - Private
    
    private func cleanupDatabaseIfRequired() {
        if let isDatabaseCleanupTaskCompleted = isDatabaseCleanupTaskCompleted,
           !isDatabaseCleanupTaskCompleted {
            self.isDatabaseCleanupTaskCompleted = true
            cleanupDatabase()
        }
    }
    
    private func cleanupDatabase() {
        guard let context = store.stack.newBackgroundContext() else { return }
        
        context.performAndWait {
            let transferList = MEGASdk.shared.transfers
            MEGALogDebug("[ChatUploader] transfer list count : \(transferList.size)")
            let sdkTransfers = (0..<transferList.size).compactMap { transferList.transfer(at: $0) }
            self.store.fetchAllChatUploadTransfer(context: context).forEach { transfer in
                if transfer.nodeHandle == nil {
                    MEGALogDebug("[ChatUploader] transfer task not completed \(transfer.index) : \(transfer.filepath)")
                    
                    let foundTransfers = sdkTransfers.filter({
                        return $0.path == transfer.filepath
                    })
                    
                    if !foundTransfers.isEmpty {
                        transfer.transferTag = nil
                        MEGALogDebug("[ChatUploader] transfer tag set to nil at \(transfer.index) : \(transfer.filepath)")
                    } else {
                        context.delete(transfer)
                        MEGALogDebug("[ChatUploader] Deleted the transfer task \(transfer.index) : \(transfer.filepath)")
                    }
                } else {
                    MEGALogDebug("[ChatUploader] transfer task is already completed \(transfer.index) : \(transfer.filepath)")
                }
            }
            
            self.store.save(context)
        }
    }
    
    private func updateDatabase(withChatRoomIdString chatRoomIdString: String, context: NSManagedObjectContext) {
        context.performAndWait {
            let allTransfers = store.fetchAllChatUploadTransfer(withChatRoomId: chatRoomIdString, context: context)
            allTransfers.forEach { transfer in
                MEGALogInfo("[ChatUploader] transfer index \(transfer.index) with file path \(transfer.filepath)")
            }
            let index = allTransfers.firstIndex(where: { $0.nodeHandle == nil })
            MEGALogInfo("[ChatUploader] transfer found at index \(index ?? -1)")
            if let totalIndexes = (index == nil) ? allTransfers.count : index {
                (0..<totalIndexes).forEach { index in
                    let transfer = allTransfers[index]
                    if let handle = transfer.nodeHandle,
                       let nodeHandle = UInt64(handle),
                       let chatRoomId = UInt64(chatRoomIdString) {
                        
                        let dispatchGroup = DispatchGroup()
                        dispatchGroup.enter()

                        let requestDelegate = ChatRequestDelegate { _ in
                            dispatchGroup.leave()
                        }
                        if let appData = transfer.appData, appData.contains("attachVoiceClipToChatID") {
                            MEGAChatSdk.shared.attachVoiceMessage(toChat: chatRoomId, node: nodeHandle, delegate: requestDelegate)
                        } else {
                            MEGAChatSdk.shared.attachNode(toChat: chatRoomId, node: nodeHandle, delegate: requestDelegate)
                        }
                        
                        MEGALogInfo("[ChatUploader] attachment complete File path \(transfer.filepath)")
                        context.delete(transfer)
                        dispatchGroup.wait()
                    }
                }
                guard MEGASdk.isLoggedIn else { return }
                store.save(context)
            }
        }
    }
}

extension ChatUploader: MEGATransferDelegate {
    
    func onTransferStart(_ api: MEGASdk, transfer: MEGATransfer) {
        uploaderQueue.async {
            guard transfer.type == .upload,
                  let chatRoomIdString = transfer.mnz_extractChatIDFromAppData(),
                  let context = self.store.stack.newBackgroundContext() else {
                return
            }
            
            self.cleanupDatabaseIfRequired()
            
            context.performAndWait {
                let allTransfers = self.store.fetchAllChatUploadTransfer(withChatRoomId: chatRoomIdString, context: context)
                if let transferTask = allTransfers.first(
                    where: { $0.filepath == transfer.path && ($0.transferTag == nil || $0.transferTag == String(transfer.tag))}
                ) {
                    transferTask.transferTag = String(transfer.tag)
                    MEGALogInfo("[ChatUploader] updating existing row for \(transfer.path ?? "no path") with tag \(transfer.tag)")
                } else if let transferPath = transfer.path {
                    self.store.insertChatUploadTransfer(withFilepath: transferPath,
                                                        chatRoomId: chatRoomIdString,
                                                        transferTag: String(transfer.tag),
                                                        allowDuplicateFilePath: true,
                                                        context: context)
                    MEGALogInfo("[ChatUploader] inserting a new row for \(transfer.path ?? "no path") with tag \(transfer.tag)")
                }
                
                self.store.save(context)
            }
        }
    }
    
    func onTransferFinish(_ api: MEGASdk, transfer: MEGATransfer, error: MEGAError) {
        uploaderQueue.async {
            guard 
                transfer.type == .upload,
                let chatRoomIdString = transfer.mnz_extractChatIDFromAppData(),
                let context = self.store.stack.newBackgroundContext(),
                let transferPath = transfer.path,
                let transferAppData = transfer.appData
            else {
                return
            }
            
            if error.type == .apiEExist {
                self.store.deleteChatUploadTransfer(withChatRoomId: chatRoomIdString,
                                                    transferTag: String(transfer.tag),
                                                    context: context)
                let fileName = transfer.fileName ?? "no file"
                MEGALogInfo("[ChatUploader] transfer has started with exactly the same data (local path and target parent). File: %@", fileName)
                return
            }
            
            MEGALogInfo("[ChatUploader] upload complete File path \(transferPath)")

            transfer.mnz_moveFileToDestinationIfVoiceClipData()
            context.performAndWait {
                self.store.updateChatUploadTransfer(filepath: transferPath,
                                                    chatRoomId: chatRoomIdString,
                                                    nodeHandle: String(transfer.nodeHandle),
                                                    transferTag: String(transfer.tag),
                                                    appData: transferAppData,
                                                    context: context)
                self.updateDatabase(withChatRoomIdString: chatRoomIdString, context: context)
            }
        }
    }
    
}
