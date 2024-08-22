import CoreData
import MEGADomain

extension MEGAStore {
    
    func deleteQuickAccessRecentItems(completion: @escaping (Result<Void, GetFavouriteNodesErrorEntity>) -> Void) {
        guard let context = stack.newBackgroundContext() else {
            completion(.failure(.megaStore))
            return
        }
        
        context.perform {
            let fetchRequest = NSFetchRequest<any NSFetchRequestResult>(entityName: "QuickAccessWidgetRecentItem")
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
    
    func batchInsertQuickAccessRecentItems(_ items: [RecentItemEntity], completion: ((Result<Void, GetFavouriteNodesErrorEntity>) -> Void)? = nil) {
        guard !items.isEmpty else {
            completion?(.success(()))
            return
        }
        
        stack.performBackgroundTask { [weak self] context in
            guard let self else { return }
            let batchInsert = buildBatchInsertRequest(for: items)
            performBatchInsertRequest(batchInsert, context: context, completion: completion)
        }
    }
    
    private func buildBatchInsertRequest(for items: [RecentItemEntity]) -> NSBatchInsertRequest {
        var insertIndex = 0
        let batchInsert = NSBatchInsertRequest(entity: QuickAccessWidgetRecentItem.entity()) { (managedObject: NSManagedObject) -> Bool in
            guard insertIndex < items.count else { return true }
            let entity = items[insertIndex]
            
            if let recentItem = managedObject as? QuickAccessWidgetRecentItem {
                recentItem.handle = entity.base64Handle
                recentItem.name = entity.name
                recentItem.isUpdate = NSNumber(value: entity.isUpdate)
                recentItem.timestamp = entity.timestamp
            }
            
            insertIndex += 1
            return false
        }
        
        return batchInsert
    }
    
    func fetchAllQuickAccessRecentItem() -> [RecentItemEntity] {
        var items = [RecentItemEntity]()
        
        guard let context = stack.newBackgroundContext() else { return items }
        context.performAndWait {
            do {
                let fetchRequest: NSFetchRequest<QuickAccessWidgetRecentItem> = QuickAccessWidgetRecentItem.fetchRequest()
                items = try context.fetch(fetchRequest).compactMap {
                    guard let handle = $0.handle,
                          let name = $0.name,
                          let date = $0.timestamp,
                          let isUpdate = $0.isUpdate else {
                        return nil
                    }
                    
                    return RecentItemEntity(base64Handle: handle, name: name, timestamp: date, isUpdate: isUpdate.boolValue)
                }
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
    
    func batchInsertQuickAccessFavouriteItems(_ items: [FavouriteItemEntity], completion: ((Result<Void, GetFavouriteNodesErrorEntity>) -> Void)? = nil) {
        guard !items.isEmpty else {
            completion?(.success(()))
            return
        }
        
        stack.performBackgroundTask { [weak self] context in
            var insertIndex = 0
            let batchInsert = NSBatchInsertRequest(entity: QuickAccessWidgetFavouriteItem.entity()) { (managedObject: NSManagedObject) -> Bool in
                guard insertIndex < items.count else { return true }
                let entity = items[insertIndex]
                
                if let favouriteItem = managedObject as? QuickAccessWidgetFavouriteItem {
                    favouriteItem.handle = entity.base64Handle
                    favouriteItem.name = entity.name
                    favouriteItem.timestamp = entity.timestamp
                }
                
                insertIndex += 1
                return false
            }
            
            self?.performBatchInsertRequest(batchInsert, context: context, completion: completion)
        }
    }
    
    private func performBatchInsertRequest(
        _ request: NSBatchInsertRequest,
        context: NSManagedObjectContext,
        completion: ((Result<Void, GetFavouriteNodesErrorEntity>) -> Void)? = nil
    ) {
        do {
            try context.execute(request)
            completion?(.success(()))
        } catch {
            MEGALogError("error when to batch insert items \(error)")
            completion?(.failure(.megaStore))
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
    
    func fetchAllQuickAccessFavouriteItems() -> [FavouriteItemEntity] {
        var items = [FavouriteItemEntity]()
        guard let context = stack.newBackgroundContext() else { return items }
        context.performAndWait {
            do {
                let fetchRequest: NSFetchRequest<QuickAccessWidgetFavouriteItem> = QuickAccessWidgetFavouriteItem.fetchRequest()
                items = try context.fetch(fetchRequest).compactMap {
                    guard let handle = $0.handle,
                          let name = $0.name,
                          let date = $0.timestamp else { return nil }
                    return FavouriteItemEntity(base64Handle: handle, name: name, timestamp: date)
                }
                
            } catch let error as NSError {
                MEGALogError("Could not fetch [QuickAccessWidgetFavouriteItem] object for path \(error.localizedDescription)")
            }
        }
        
        return items
    }
    
    func fetchQuickAccessFavourtieItems(withLimit fetchLimit: Int?) -> [FavouriteItemEntity] {
        var items = [FavouriteItemEntity]()
        guard let context = stack.newBackgroundContext() else { return items }
        context.performAndWait {
            let fetchRequest: NSFetchRequest<QuickAccessWidgetFavouriteItem> = QuickAccessWidgetFavouriteItem.fetchRequest()
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
            
            if let fetchLimit = fetchLimit {
                fetchRequest.fetchLimit = fetchLimit
            }
            
            do {
                items = try context.fetch(fetchRequest).compactMap {
                    guard let handle = $0.handle,
                          let name = $0.name,
                          let date = $0.timestamp else { return nil }
                    return FavouriteItemEntity(base64Handle: handle, name: name, timestamp: date)
                }
            } catch let error as NSError {
                MEGALogError("Error fetching QuickAccessWidgetFavouriteItem: \(error.description)")
            }
        }
        
        return items
    }
    
    func deleteQuickAccessFavouriteItems(completion: @escaping (Result<Void, GetFavouriteNodesErrorEntity>) -> Void) {
        stack.performBackgroundTask { context in
            let fetchRequest = NSFetchRequest<any NSFetchRequestResult>(entityName: "QuickAccessWidgetFavouriteItem")
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
