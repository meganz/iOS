

@objc class ChatUploader: NSObject {
    @objc static let sharedInstance = ChatUploader()
    
    private var store: MEGAStore? {
        return MEGAStore.shareInstance()
    }
    
    private lazy var context: NSManagedObjectContext? = store?.childPrivateQueueContext
    
    private override init() {
        super.init()
        MEGASdkManager.sharedMEGASdk()?.add(self)
    }
    
      
    @objc func upload(filepath: String,
                      appData: String,
                      chatRoomId: UInt64,
                      parentNode: MEGANode,
                      isSourceTemporary: Bool,
                      delegate: MEGAStartUploadTransferDelegate) {
        
        MEGALogInfo("[ChatUploader] uploading File path \(filepath)")
        
        if let store = MEGAStore.shareInstance(),
            let context = store.storeStack?.viewContext {
            // insert into database only if the duplicate path does not exsist - "allowDuplicateFilePath" parameter
            store.insertChatUploadTransfer(withFilepath: filepath,
                                           chatRoomId: String(chatRoomId),
                                           transferTag: nil,
                                           allowDuplicateFilePath: false,
                                           context: context)
        }
        
        MEGASdkManager.sharedMEGASdk()?.startUploadForChat(withLocalPath: filepath,
                                                           parent: parentNode,
                                                           appData: appData,
                                                           isSourceTemporary: isSourceTemporary,
                                                           delegate: delegate)
    }
    
    @objc func cleanupDatabase() {
        guard let sdk = MEGASdkManager.sharedMEGASdk(),
            let store = store,
            let context = context else  {
            return
        }
        
        context.perform {
            let transferList = sdk.transfers
            let sdkTransfers = (0..<transferList.size.intValue).compactMap { transferList.transfer(at: $0) }
            store.fetchAllChatUploadTransfer(context: context)?.forEach { transfer in
                let foundTransfer = sdkTransfers.filter({ String($0.tag) == transfer.transferTag })
                if foundTransfer.count == 0 {
                    context.delete(transfer)
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
                        MEGASdkManager.sharedMEGAChatSdk()?.attachNode(toChat: chatRoomId, node: nodeHandle)
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
                                           context: context)
            self.updateDatabase(withChatRoomIdString: chatRoomIdString, context: context)
        }
    }
    
}
