
extension MEGAStore {
    
    func deleteQuickAccessRecentItems(with context: NSManagedObjectContext, completion: @escaping (Result<Void, QuickAccessWidgetErrorEntity>) -> Void) {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "QuickAccessWidgetRecentItem")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

        do {
            try context.execute(deleteRequest)
            completion(.success(()))
        } catch let error as NSError {
            MEGALogError("Could not delete QuickAccessWidgetRecentItem object: \(error.localizedDescription)")
            completion(.failure(.megaStore))
        }
    }
    
    func insertQuickAccessRecentItem(withBase64Handle base64Handle: String,
                                     name: String,
                                     isUpdate: Bool,
                                     timestamp: Date,
                                     context: NSManagedObjectContext) {
        let quickAccessRecentItem = QuickAccessWidgetRecentItem.createInstance(withContext: context)
        quickAccessRecentItem.handle = base64Handle
        quickAccessRecentItem.name = name
        quickAccessRecentItem.isUpdate = isUpdate as NSNumber
        quickAccessRecentItem.timestamp = timestamp
        MEGAStore.shareInstance()?.save(context)
    }
    
    func fetchAllQuickAccessRecentItem(context: NSManagedObjectContext) -> [QuickAccessWidgetRecentItem]? {
        do {
            let fetchRequest: NSFetchRequest<QuickAccessWidgetRecentItem> = QuickAccessWidgetRecentItem.fetchRequest()
            return try context.fetch(fetchRequest)
        } catch let error as NSError {
            MEGALogError("Could not fetch [QuickAccessWidgetRecentItem] object for path \(error.localizedDescription)")
            return nil
        }
    }
    
    func insertQuickAccessFavouriteItem(withBase64Handle base64Handle: String,
                                        name: String,
                                        timestamp: Date,
                                        context: NSManagedObjectContext) {
        let quickAccessWidgetFavouriteItem = QuickAccessWidgetFavouriteItem.createInstance(withContext: context)
        quickAccessWidgetFavouriteItem.handle = base64Handle
        quickAccessWidgetFavouriteItem.name = name
        quickAccessWidgetFavouriteItem.timestamp = timestamp
        MEGAStore.shareInstance().save(context)
    }
    
    func deleteQuickAccessFavouriteItem(withBase64Handle base64Handle: String, inContext context: NSManagedObjectContext) {
        
        let fetchRequest: NSFetchRequest<QuickAccessWidgetFavouriteItem> = QuickAccessWidgetFavouriteItem.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "handle == %@", base64Handle)

        do {
            if let object = try context.fetch(fetchRequest).first {
                context.delete(object)
                MEGAStore.shareInstance().save(context)
            } else {
                MEGALogError("Could not find QuickAccessWidgetFavouriteItem object to delete")
            }
        } catch let error as NSError {
            MEGALogError("Could not delete QuickAccessWidgetFavouriteItem object: \(error.localizedDescription)")
        }
    }
    
    func fetchAllQuickAccessFavouriteItems(context: NSManagedObjectContext) -> [QuickAccessWidgetFavouriteItem]? {
        do {
            let fetchRequest: NSFetchRequest<QuickAccessWidgetFavouriteItem> = QuickAccessWidgetFavouriteItem.fetchRequest()
            return try context.fetch(fetchRequest)
        } catch let error as NSError {
            MEGALogError("Could not fetch [QuickAccessWidgetFavouriteItem] object for path \(error.localizedDescription)")
            return nil
        }
    }
    
    func fetchQuickAccessFavourtieItems(withLimit fetchLimit: Int?, context: NSManagedObjectContext) -> [QuickAccessWidgetFavouriteItem]? {
        let fetchRequest: NSFetchRequest<QuickAccessWidgetFavouriteItem> = QuickAccessWidgetFavouriteItem.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
     
        if let fetchLimit = fetchLimit {
            fetchRequest.fetchLimit = fetchLimit
        }
        
        do {
            let objects = try context.fetch(fetchRequest)
            return objects
        } catch let error as NSError {
            MEGALogError("Error fetching QuickAccessWidgetFavouriteItem: \(error.description)")
            return nil
        }
    }
    
    func deleteQuickAccessFavouriteItems(with context: NSManagedObjectContext, completion: @escaping (Result<Void, QuickAccessWidgetErrorEntity>) -> Void) {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "QuickAccessWidgetFavouriteItem")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

        do {
            try context.execute(deleteRequest)
            completion(.success(()))
        } catch let error as NSError {
            MEGALogError("Could not delete QuickAccessWidgetFavouriteItem object: \(error.localizedDescription)")
            completion(.failure(.megaStore))
        }
    }
}
