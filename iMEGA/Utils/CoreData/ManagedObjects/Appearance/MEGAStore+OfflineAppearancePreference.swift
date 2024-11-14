import Foundation

extension MEGAStore {
    
    @objc func insertOrUpdateOfflineSortType(path: String, sortType: Int) {
        guard let context = stack.viewContext else { return }
        
        if let offlineAppearancePreference = fetchOfflineAppearancePreference(path: path) {
            offlineAppearancePreference.sortType = NSNumber(value: sortType)
        } else {
            let offlineAppearancePreference = NSEntityDescription.insertNewObject(forEntityName: "OfflineAppearancePreference", into: context) as! OfflineAppearancePreference
            offlineAppearancePreference.localPath = path
            offlineAppearancePreference.sortType = NSNumber(value: sortType)
        }
        
        save(context)
    }
    
    @objc func insertOrUpdateOfflineViewMode(path: String, viewMode: Int) {
        guard let context: NSManagedObjectContext = {
            if Thread.isMainThread {
                return stack.viewContext
            } else {
                return stack.newBackgroundContext()
            }
        }() else { return }
        
        if let offlineAppearancePreference = fetchOfflineAppearancePreference(path: path) {
            offlineAppearancePreference.viewMode = NSNumber(value: viewMode)
        } else {
            let offlineAppearancePreference = NSEntityDescription.insertNewObject(forEntityName: "OfflineAppearancePreference", into: context) as! OfflineAppearancePreference
            offlineAppearancePreference.localPath = path
            offlineAppearancePreference.viewMode = NSNumber(value: viewMode)
        }
        
        save(context)
    }
    
    @objc func fetchOfflineAppearancePreference(path: String) -> OfflineAppearancePreference? {
        guard let context = stack.viewContext else { return nil }
        
        let fetchRequest = NSFetchRequest<OfflineAppearancePreference>(entityName: "OfflineAppearancePreference")
        fetchRequest.predicate = NSPredicate(format: "localPath == %@", path)
        
        var offlineAppearancePreferencesArray: [OfflineAppearancePreference]
        do {
            offlineAppearancePreferencesArray = try context.fetch(fetchRequest)
            
            guard let offlineAppearancePreference = offlineAppearancePreferencesArray.first else {
                return nil
            }
            
            return offlineAppearancePreference
        } catch let error as NSError {
            MEGALogError("Could not fetch [OfflineAppearancePreference] \(error)")
            
            return nil
        }
    }
    
    // Thread-safe method to fetch OfflineAppearancePreference.sortType
    @objc func fetchOfflineAppearancePreferenceSortType(path: String) -> NSNumber? {
         guard let context: NSManagedObjectContext = {
             if Thread.isMainThread {
                 return stack.viewContext
             } else {
                 return stack.newBackgroundContext()
             }
         }() else { return nil }
         
         var result: NSNumber?
         
         context.performAndWait {
             let fetchRequest = NSFetchRequest<OfflineAppearancePreference>(entityName: "OfflineAppearancePreference")
             fetchRequest.predicate = NSPredicate(format: "localPath == %@", path)
             do {
                 result = try context.fetch(fetchRequest).first?.sortType
             } catch let error as NSError {
                 MEGALogError("Could not fetch [OfflineAppearancePreference] \(error)")
             }
         }
        
        return result
     }
    
    @objc func fetchOfflineAppearancePreferences() -> [OfflineAppearancePreference]? {
        guard let context = stack.viewContext else { return nil }
        
        let fetchRequest = NSFetchRequest<OfflineAppearancePreference>(entityName: "OfflineAppearancePreference")
        
        var offlineAppearancePreferencesArray: [OfflineAppearancePreference]
        do {
            offlineAppearancePreferencesArray = try context.fetch(fetchRequest)
            
            return offlineAppearancePreferencesArray
        } catch let error as NSError {
            MEGALogError("Could not fetch [OfflineAppearancePreference] \(error), \(error.userInfo)")
            
            return nil
        }
    }
    
    @objc func deleteOfflineAppearancePreference(path: String) {
        guard let context = stack.viewContext else { return }
        
        if let offlineAppearancePreference = fetchOfflineAppearancePreference(path: path) {
            MEGALogDebug("Deleted OfflineAppearancePreference \(offlineAppearancePreference)")
            context.delete(offlineAppearancePreference)
            
            save(context)
        }
    }
    
    @objc func deleteOfflineAppearancePreferences() {
        guard let context = stack.viewContext else { return }
        guard let offlineAppearancePreferencesArray = fetchOfflineAppearancePreferences() else { return }
        
        for offlineAppearancePreference in offlineAppearancePreferencesArray {
            MEGALogDebug("Delete OfflineAppearancePreference \(offlineAppearancePreference)")
            context.delete(offlineAppearancePreference)
        }
        save(context)
    }
}
