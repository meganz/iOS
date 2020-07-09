

extension MEGAStore {
    
    @objc func insertChatUploadTransfer(withFilepath filepath: String,
                                        chatRoomId: String,
                                        transferTag: String?,
                                        allowDuplicateFilePath: Bool,
                                        context: NSManagedObjectContext) {
        if !allowDuplicateFilePath {
            if let transfer = fetchChatUploadTransfer(filepath: filepath, chatRoomId: chatRoomId, transferTag: transferTag, context: context) {
                MEGALogError("ChatUploadTransfer object already exsists \(transfer.filepath)")
                return
            }
        }
        
        let mostRecentTransferObject = fetchMostRecentChatUploadTransfer(context: context)
        let transferObject = ChatUploadTransfer.createInstance(withContext: context)
        transferObject.index = (mostRecentTransferObject?.index ?? 0) + 1
        transferObject.filepath = filepath
        transferObject.chatRoomId = chatRoomId
        transferObject.transferTag = transferTag
        MEGAStore.shareInstance()?.save(context)
    }
    
    func updateChatUploadTransfer(filepath: String, chatRoomId: String, nodeHandle: String, transferTag: String, context: NSManagedObjectContext) {
        if let transfer = fetchChatUploadTransfer(filepath: filepath, chatRoomId: chatRoomId, transferTag: transferTag, context: context) {
            transfer.nodeHandle = nodeHandle
            MEGAStore.shareInstance()?.save(context)
        } else {
            MEGALogError("ChatUploadTransfer object does not exsists")
            return
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
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "index", ascending: true)]

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
    
    func fetchChatUploadTransfer(filepath: String, chatRoomId: String, transferTag: String?, context: NSManagedObjectContext) -> ChatUploadTransfer? {
        let fetchRequest: NSFetchRequest<ChatUploadTransfer> = ChatUploadTransfer.fetchRequest()
        
        if let transferTag = transferTag {
            fetchRequest.predicate = NSPredicate(format: "filepath == %@ AND chatRoomId == %@ AND transferTag == %@", filepath, chatRoomId, transferTag)
        } else {
            fetchRequest.predicate = NSPredicate(format: "filepath == %@ AND chatRoomId == %@", filepath, chatRoomId)
        }
        
        do {
            return try context.fetch(fetchRequest).first
        } catch let error as NSError {
            MEGALogError("Could not fetch ChatUploadTransfer object for path \(filepath) : \(error.localizedDescription)")
            return nil
        }
    }
    
    func deleteChatUploadTransfer(withChatRoomId chatRoomId: String, transferTag: String, context: NSManagedObjectContext) {
        let fetchRequest: NSFetchRequest<ChatUploadTransfer> = ChatUploadTransfer.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "chatRoomId == %@ AND transferTag == %@", chatRoomId, transferTag)
        do {
            if let object = try context.fetch(fetchRequest).first {
                context.delete(object)
                MEGAStore.shareInstance()?.save(context)
            } else {
                MEGALogError("Could not find ChatUploadTransfer object to delete")
            }
        } catch let error as NSError {
            MEGALogError("Could not delete ChatUploadTransfer object : \(error.localizedDescription)")
        }
    }

    
}
