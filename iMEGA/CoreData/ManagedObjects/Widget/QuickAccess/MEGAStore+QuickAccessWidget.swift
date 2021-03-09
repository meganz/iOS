
extension MEGAStore {
    
    func deleteQuickAccessRecentItems(completion: @escaping (Result<Void, QuickAccessWidgetErrorEntity>) -> Void) {
        let context = stack.newBackgroundContext()
        context.perform {
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
    }
    
    func insertQuickAccessRecentItem(withBase64Handle base64Handle: String,
                                     name: String,
                                     isUpdate: Bool,
                                     timestamp: Date) {
        stack.performBackgroundTask { context in
            let quickAccessRecentItem = QuickAccessWidgetRecentItem.createInstance(withContext: context)
            quickAccessRecentItem.handle = base64Handle
            quickAccessRecentItem.name = name
            quickAccessRecentItem.isUpdate = isUpdate as NSNumber
            quickAccessRecentItem.timestamp = timestamp
            self.save(context)
        }
    }
    
    func fetchAllQuickAccessRecentItem() -> [QuickAccessWidgetRecentItem] {
        let context = stack.newBackgroundContext()
        var items = [QuickAccessWidgetRecentItem]()
        
        context.performAndWait {
            do {
                let fetchRequest: NSFetchRequest<QuickAccessWidgetRecentItem> = QuickAccessWidgetRecentItem.fetchRequest()
                items = try context.fetch(fetchRequest)
            } catch let error as NSError {
                MEGALogError("Could not fetch [QuickAccessWidgetRecentItem] object for path \(error.localizedDescription)")
            }
        }
        
        return items
    }
    
    func insertQuickAccessFavouriteItem(withBase64Handle base64Handle: String,
                                        name: String,
                                        timestamp: Date) {
        stack.performBackgroundTask { context in
            let quickAccessWidgetFavouriteItem = QuickAccessWidgetFavouriteItem.createInstance(withContext: context)
            quickAccessWidgetFavouriteItem.handle = base64Handle
            quickAccessWidgetFavouriteItem.name = name
            quickAccessWidgetFavouriteItem.timestamp = timestamp
            self.save(context)
        }
    }
    
    func deleteQuickAccessFavouriteItem(withBase64Handle base64Handle: String) {
        stack.performBackgroundTask { context in
            let fetchRequest: NSFetchRequest<QuickAccessWidgetFavouriteItem> = QuickAccessWidgetFavouriteItem.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "handle == %@", base64Handle)
            
            do {
                if let object = try context.fetch(fetchRequest).first {
                    context.delete(object)
                    self.save(context)
                } else {
                    MEGALogError("Could not find QuickAccessWidgetFavouriteItem object to delete")
                }
            } catch let error as NSError {
                MEGALogError("Could not delete QuickAccessWidgetFavouriteItem object: \(error.localizedDescription)")
            }
        }
    }
    
    func fetchAllQuickAccessFavouriteItems() -> [QuickAccessWidgetFavouriteItem] {
        let context = stack.newBackgroundContext()
        var items = [QuickAccessWidgetFavouriteItem]()
        
        context.performAndWait {
            do {
                let fetchRequest: NSFetchRequest<QuickAccessWidgetFavouriteItem> = QuickAccessWidgetFavouriteItem.fetchRequest()
                items = try context.fetch(fetchRequest)
            } catch let error as NSError {
                MEGALogError("Could not fetch [QuickAccessWidgetFavouriteItem] object for path \(error.localizedDescription)")
            }
        }
        
        return items
    }
    
    func fetchQuickAccessFavourtieItems(withLimit fetchLimit: Int?) -> [QuickAccessWidgetFavouriteItem] {
        let context = stack.newBackgroundContext()
        var items = [QuickAccessWidgetFavouriteItem]()
        
        context.performAndWait {
            let fetchRequest: NSFetchRequest<QuickAccessWidgetFavouriteItem> = QuickAccessWidgetFavouriteItem.fetchRequest()
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
            
            if let fetchLimit = fetchLimit {
                fetchRequest.fetchLimit = fetchLimit
            }
            
            do {
                items = try context.fetch(fetchRequest)
            } catch let error as NSError {
                MEGALogError("Error fetching QuickAccessWidgetFavouriteItem: \(error.description)")
            }
        }
        
        return items
    }
    
    func deleteQuickAccessFavouriteItems(completion: @escaping (Result<Void, QuickAccessWidgetErrorEntity>) -> Void) {
        stack.performBackgroundTask { context in
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
}
