

extension MEGAStore {
    
    @objc func insertChatUploadTransfer(withFilepath filepath: String, chatRoomId: String, context: NSManagedObjectContext) {
        if let transfer = fetchChatUploadTransfer(filepath: filepath, chatRoomId: chatRoomId, context: context) {
            MEGALogError("ChatUploadTransfer object already exsists \(transfer.filepath)")
            return
        } else {
            let mostRecentTransferObject = fetchMostRecentChatUploadTransfer(context: context)
            let transferObject = ChatUploadTransfer.createInstance(withContext: context)
            transferObject.index = (mostRecentTransferObject?.index ?? 0) + 1
            transferObject.filepath = filepath
            transferObject.chatRoomId = chatRoomId
            MEGAStore.shareInstance()?.save(context)
        }
    }
    
    func updateChatUploadTransfer(filepath: String, chatRoomId: String, nodeHandle: String, context: NSManagedObjectContext) {
        if let transfer = fetchChatUploadTransfer(filepath: filepath, chatRoomId: chatRoomId, context: context) {
            transfer.nodeHandle = nodeHandle
            MEGAStore.shareInstance()?.save(context)
        } else {
            MEGALogError("ChatUploadTransfer object does not exsists")
            return
        }
    }
    
    @objc func fetchAllChatUploadTransfers(forChatRoomId chatRoomId: String, context: NSManagedObjectContext) -> [ChatUploadTransfer]? {
        let fetchRequest: NSFetchRequest<ChatUploadTransfer> = ChatUploadTransfer.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "chatRoomId == %llu", chatRoomId)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "index", ascending: true)]

        do {
            return try context.fetch(fetchRequest)
        } catch let error as NSError {
            MEGALogError("Could not fetch [ChatUploadTransfer] \(error.localizedDescription)")
            return nil
        }
    }
    
    func fetchMostRecentChatUploadTransfer(context: NSManagedObjectContext) -> ChatUploadTransfer? {
        let fetchRequest: NSFetchRequest<ChatUploadTransfer> = ChatUploadTransfer.fetchRequest()
        fetchRequest.fetchLimit = 1
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "index", ascending: false)]
        
        do {
            return try context.fetch(fetchRequest).last
        } catch let error as NSError {
            MEGALogError("Could not fetch ChatUploadTransfer \(error.localizedDescription)")
            return nil
        }
    }
    
    func fetchAllChatUploadTransfer(withChatRoomId chatRoomId: String, context: NSManagedObjectContext) -> [ChatUploadTransfer]? {
        let fetchRequest: NSFetchRequest<ChatUploadTransfer> = ChatUploadTransfer.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "chatRoomId == %@", chatRoomId)
        
        do {
            return try context.fetch(fetchRequest)
        } catch let error as NSError {
            MEGALogError("Could not fetch [ChatUploadTransfer] object for path \(error.localizedDescription)")
            return nil
        }
    }
    
    func fetchAllChatUploadTransfer(context: NSManagedObjectContext) -> [ChatUploadTransfer]? {
        do {
            return try context.fetch(ChatUploadTransfer.fetchRequest())
        } catch let error as NSError {
            MEGALogError("Could not fetch [ChatUploadTransfer] object for path \(error.localizedDescription)")
            return nil
        }
    }
    
    func fetchChatUploadTransfer(filepath: String, chatRoomId: String, context: NSManagedObjectContext) -> ChatUploadTransfer? {
        let fetchRequest: NSFetchRequest<ChatUploadTransfer> = ChatUploadTransfer.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "filepath == %@ AND chatRoomId == %@", filepath, chatRoomId)
        
        do {
            return try context.fetch(fetchRequest).first
        } catch let error as NSError {
            MEGALogError("Could not fetch ChatUploadTransfer object for path \(filepath) : \(error.localizedDescription)")
            return nil
        }
    }
    
    @objc func deleteChatUploadTransfer(forFilepath filepath: String, chatRoomId: String, context: NSManagedObjectContext) {
        if let chatUploadTransfer = fetchChatUploadTransfer(filepath: filepath, chatRoomId: chatRoomId, context: context) {
            MEGALogDebug("Deleted ChatUploadTransfer \(chatUploadTransfer)")
            
        }
    }
}
