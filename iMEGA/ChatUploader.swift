

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
        
        if let store = MEGAStore.shareInstance(), let context = store.storeStack?.viewContext {
            store.insertChatUploadTransfer(withFilepath: filepath, chatRoomId: String(chatRoomId), context: context)
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
        
        let transferList = sdk.transfers
        let sdkTransfers = (0..<transferList.size.intValue).compactMap { transferList.transfer(at: $0) }
        store.fetchAllChatUploadTransfer(context: context)?.forEach { transfer in
            let foundTransfer = sdkTransfers.filter({ $0.path == transfer.filepath })
            if foundTransfer.count == 0 {
                context.delete(transfer)
            }
        }
        
        MEGAStore.shareInstance()?.save(context)
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
                        MEGALogInfo("[ChatUploader] attchment complete File path \(transfer.filepath)")
                        context.delete(transfer)
                    }
                }
                
                MEGAStore.shareInstance()?.save(context)
            }
        }
    }
}

extension ChatUploader: MEGATransferDelegate {
    
    func onTransferFinish(_ api: MEGASdk, transfer: MEGATransfer, error: MEGAError) {
        guard transfer.type == .upload,
            let chatRoomIdString = transfer.mnz_extractChatIDFromAppData(),
            let store = store,
            let context = context else {
                return
        }
        
        if (error.type == .apiEExist) {
            MEGALogInfo("[ChatUploader]Transfer has started with exactly the same data (local path and target parent). File: %@", transfer.fileName);
            return;
        }
        
        MEGALogInfo("[ChatUploader] upload complete File path \(transfer.path ?? "No file path found")")

        transfer.mnz_moveFileToDestinationIfVoiceClipData()
        context.perform {
            store.updateChatUploadTransfer(filepath: transfer.path,
                                           chatRoomId: chatRoomIdString,
                                           nodeHandle: String(transfer.nodeHandle),
                                           context: context)
            self.updateDatabase(withChatRoomIdString: chatRoomIdString, context: context)
        }
    }
    
}
