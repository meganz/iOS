

@objc class ChatUploader: NSObject {
    @objc static let sharedInstance = ChatUploader()
    
    private var store: MEGAStore? {
        return MEGAStore.shareInstance()
    }
    
    private lazy var context: NSManagedObjectContext? = store?.childPrivateQueueContext
    private var isDatabaseCleanupTaskCompleted: Bool?
    
    private override init() { super.init() }
    
    @objc func setup() {
        isDatabaseCleanupTaskCompleted = false
        MEGASdkManager.sharedMEGASdk()?.add(self)
    }
    
    @objc func upload(filepath: String,
                      appData: String,
                      chatRoomId: UInt64,
                      parentNode: MEGANode,
                      isSourceTemporary: Bool,
                      delegate: MEGAStartUploadTransferDelegate) {
        
        MEGALogInfo("[ChatUploader] uploading File path \(filepath)")
        cleanupDatabaseIfRequired()
        if let store = store,
            let context = context {
            context.perform {
                MEGALogInfo("[ChatUploader] inserted new entry File path \(filepath)")
                // insert into database only if the duplicate path does not exsist - "allowDuplicateFilePath" parameter
                store.insertChatUploadTransfer(withFilepath: filepath,
                                               chatRoomId: String(chatRoomId),
                                               transferTag: nil,
                                               allowDuplicateFilePath: false,
                                               context: context)
                
                MEGALogInfo("[ChatUploader] SDK upload started for File path \(filepath)")
                MEGASdkManager.sharedMEGASdk()?.startUploadForChat(withLocalPath: filepath,
                                                                   parent: parentNode,
                                                                   appData: appData,
                                                                   isSourceTemporary: isSourceTemporary,
                                                                   delegate: delegate)
            }
        }
    }
    
    private func cleanupDatabaseIfRequired() {
        if let isDatabaseCleanupTaskCompleted = isDatabaseCleanupTaskCompleted,
            !isDatabaseCleanupTaskCompleted {
            self.isDatabaseCleanupTaskCompleted = true
            cleanupDatabase()
        }
    }
    
    private func cleanupDatabase() {
        guard let sdk = MEGASdkManager.sharedMEGASdk(),
            let store = store,
            let context = context else  {
            return
        }
        
        context.perform {
            let transferList = sdk.transfers
            MEGALogDebug("[ChatUploader] transfer list count : \(transferList.size.intValue)")
            let sdkTransfers = (0..<transferList.size.intValue).compactMap { transferList.transfer(at: $0) }
            store.fetchAllChatUploadTransfer(context: context)?.forEach { transfer in
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
            
            MEGAStore.shareInstance()?.save(context)
        }
    }
    
    private func updateDatabase(withChatRoomIdString chatRoomIdString: String, context: NSManagedObjectContext) {
        if let allTransfers = MEGAStore.shareInstance()?.fetchAllChatUploadTransfer(withChatRoomId: chatRoomIdString, context: context) {
            let index = allTransfers.firstIndex(where: { $0.nodeHandle == nil })
            if let totalIndexes = (index == nil) ? allTransfers.count : index {
                (0..<totalIndexes).forEach { index in
                    let transfer = allTransfers[index]
                    if let handle = transfer.nodeHandle,
                        let nodeHandle = UInt64(handle),
                        let chatRoomId = UInt64(chatRoomIdString) {
                        
                        if let appData = transfer.appData, appData.contains("attachVoiceClipToChatID") {
                            MEGASdkManager.sharedMEGAChatSdk()?.attachVoiceMessage(toChat: chatRoomId, node: nodeHandle)
                        } else {
                            MEGASdkManager.sharedMEGAChatSdk()?.attachNode(toChat: chatRoomId, node: nodeHandle)
                        }
                        
                        MEGALogInfo("[ChatUploader] attachment complete File path \(transfer.filepath)")
                        context.delete(transfer)
                    }
                }
                
                MEGAStore.shareInstance()?.save(context)
            }
        }
    }
}

extension ChatUploader: MEGATransferDelegate {
    
    func onTransferStart(_ api: MEGASdk, transfer: MEGATransfer) {
        guard transfer.type == .upload,
            let chatRoomIdString = transfer.mnz_extractChatIDFromAppData(),
            let store = store,
            let context = context else {
                return
        }
        
        cleanupDatabaseIfRequired()
        
        context.perform {
            if let allTransfers = MEGAStore.shareInstance()?.fetchAllChatUploadTransfer(withChatRoomId: chatRoomIdString, context: context) {
                if let transferTask = allTransfers.filter({ $0.filepath == transfer.path && ($0.transferTag == nil || $0.transferTag == String(transfer.tag))}).first {
                    transferTask.transferTag = String(transfer.tag)
                    MEGALogInfo("[ChatUploader] updating existing row for \(transfer.path ?? "no path") with tag \(transfer.tag)")
                } else {
                    store.insertChatUploadTransfer(withFilepath: transfer.path,
                                                   chatRoomId: chatRoomIdString,
                                                   transferTag: String(transfer.tag),
                                                   allowDuplicateFilePath: true,
                                                   context: context)
                    MEGALogInfo("[ChatUploader] inserting a new row for \(transfer.path ?? "no path") with tag \(transfer.tag)")
                }
            }
            
            MEGAStore.shareInstance()?.save(context)
        }
    }
    
    func onTransferFinish(_ api: MEGASdk, transfer: MEGATransfer, error: MEGAError) {
        guard transfer.type == .upload,
            let chatRoomIdString = transfer.mnz_extractChatIDFromAppData(),
            let store = store,
            let context = context else {
                return
        }
        
        if (error.type == .apiEExist) {
            MEGAStore.shareInstance()?.deleteChatUploadTransfer(withChatRoomId: chatRoomIdString,
                                                                transferTag: String(transfer.tag),
                                                                context: context)
            MEGALogInfo("[ChatUploader] transfer has started with exactly the same data (local path and target parent). File: %@", transfer.fileName);
            return;
        }
        
        MEGALogInfo("[ChatUploader] upload complete File path \(transfer.path ?? "No file path found")")

        transfer.mnz_moveFileToDestinationIfVoiceClipData()
        context.perform {
            store.updateChatUploadTransfer(filepath: transfer.path,
                                           chatRoomId: chatRoomIdString,
                                           nodeHandle: String(transfer.nodeHandle),
                                           transferTag: String(transfer.tag),
                                           appData: transfer.appData,
                                           context: context)
            self.updateDatabase(withChatRoomIdString: chatRoomIdString, context: context)
        }
    }
    
}
