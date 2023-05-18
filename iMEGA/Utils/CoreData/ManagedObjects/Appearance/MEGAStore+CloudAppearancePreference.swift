
import Foundation

extension MEGAStore {
    
    @objc func insertOrUpdateCloudSortType(handle: UInt64, sortType: Int) {
        guard let context = stack.viewContext else { return }
        
        if let cloudAppearancePreference = fetchCloudAppearancePreference(handle: handle) {
            cloudAppearancePreference.sortType = NSNumber(value: sortType)
        } else {
            let cloudAppearancePreference = NSEntityDescription.insertNewObject(forEntityName: "CloudAppearancePreference", into: context) as! CloudAppearancePreference
            cloudAppearancePreference.handle = NSNumber(value: handle)
            cloudAppearancePreference.sortType = NSNumber(value: sortType)
        }
        
        MEGAStore.shareInstance().save(context)
    }
    
    @objc func insertOrUpdateCloudViewMode(handle: UInt64, viewMode: Int) {
        guard let context = stack.viewContext else { return }
        
        if let cloudAppearancePreference = fetchCloudAppearancePreference(handle: handle) {
            cloudAppearancePreference.viewMode = NSNumber(value: viewMode)
        } else {
            let cloudAppearancePreference = NSEntityDescription.insertNewObject(forEntityName: "CloudAppearancePreference", into: context) as! CloudAppearancePreference
            cloudAppearancePreference.handle = NSNumber(value: handle)
            cloudAppearancePreference.viewMode = NSNumber(value: viewMode)
        }
        
        MEGAStore.shareInstance().save(context)
    }
    
    @objc func fetchCloudAppearancePreference(handle: UInt64) -> CloudAppearancePreference? {
        guard let context = stack.viewContext else { return nil }
        
        return fetchCloudAppearancePreference(handle: handle, context: context)
    }
    
    @objc func fetchCloudAppearancePreference(handle: UInt64, context: NSManagedObjectContext) -> CloudAppearancePreference? {
        let fetchRequest = NSFetchRequest<CloudAppearancePreference>(entityName: "CloudAppearancePreference")
        fetchRequest.predicate = NSPredicate(format: "handle == %@", handle as NSNumber)
        
        var cloudAppearancePreferencesArray : [CloudAppearancePreference]
        do {
            cloudAppearancePreferencesArray = try context.fetch(fetchRequest)
            
            guard let cloudAppearancePreference = cloudAppearancePreferencesArray.first else {
                return nil
            }
            
            return cloudAppearancePreference
        } catch let error as NSError {
            MEGALogError("Could not fetch [CloudAppearancePreference] \(error)")
            
            return nil
        }
    }
    
    @objc func fetchCloudAppearancePreferences() -> [CloudAppearancePreference]? {
        guard let context = stack.viewContext else { return nil }
        
        let fetchRequest = NSFetchRequest<CloudAppearancePreference>(entityName: "CloudAppearancePreference")
        
        var cloudAppearancePreferencesArray: [CloudAppearancePreference]
        do {
            cloudAppearancePreferencesArray = try context.fetch(fetchRequest)
            
            return cloudAppearancePreferencesArray
        } catch let error as NSError {
            MEGALogError("Could not fetch [CloudAppearancePreference] \(error), \(error.userInfo)")
            
            return nil
        }
    }
    
    @objc func deleteCloudAppearancePreference(handle : UInt64) {
        guard let context = stack.viewContext else { return }
        
        if let cloudAppearancePreference = fetchCloudAppearancePreference(handle: handle) {
            MEGALogDebug("Delete CloudAppearancePreference \(cloudAppearancePreference)")
            context.delete(cloudAppearancePreference)
            
            MEGAStore.shareInstance().save(context)
        } else {
            MEGALogError("Failed to delete CloudAppearancePreference \(handle), it does not exist on Core Data.")
        }
    }
    
    @objc func deleteAllCloudAppearancePreferences() {
        guard let context = stack.viewContext else { return }
        
        guard let cloudAppearancePreferencesArray = fetchCloudAppearancePreferences() else { return }
        
        for cloudAppearancePreference in cloudAppearancePreferencesArray {
            MEGALogDebug("Delete CloudAppearancePreference \(cloudAppearancePreference)")
            context.delete(cloudAppearancePreference)
        }
        
        MEGAStore.shareInstance().save(context)
    }
}
