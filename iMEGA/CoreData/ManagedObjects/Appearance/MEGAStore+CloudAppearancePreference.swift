
import Foundation

extension MEGAStore {
    
    @objc func insertOrUpdateCloudSortType(handle: UInt64, sortType: Int) {
        if let cloudAppearancePreference = fetchCloudAppearancePreference(handle: handle) {
            cloudAppearancePreference.sortType = NSNumber.init(value: sortType)
        } else {
            let cloudAppearancePreference = NSEntityDescription.insertNewObject(forEntityName: "CloudAppearancePreference", into: stack.viewContext) as! CloudAppearancePreference
            cloudAppearancePreference.handle = NSNumber.init(value: handle)
            cloudAppearancePreference.sortType = NSNumber.init(value: sortType)
        }
        
        MEGAStore.shareInstance()?.save(stack.viewContext)
    }
    
    @objc func insertOrUpdateCloudViewMode(handle: UInt64, viewMode: Int) {
        if let cloudAppearancePreference = fetchCloudAppearancePreference(handle: handle) {
            cloudAppearancePreference.viewMode = NSNumber.init(value: viewMode)
        } else {
            let cloudAppearancePreference = NSEntityDescription.insertNewObject(forEntityName: "CloudAppearancePreference", into: stack.viewContext) as! CloudAppearancePreference
            cloudAppearancePreference.handle = NSNumber.init(value: handle)
            cloudAppearancePreference.viewMode = NSNumber.init(value: viewMode)
        }
        
        MEGAStore.shareInstance()?.save(stack.viewContext)
    }
    
    @objc func fetchCloudAppearancePreference(handle: UInt64) -> CloudAppearancePreference? {
        let fetchRequest = NSFetchRequest<CloudAppearancePreference>(entityName: "CloudAppearancePreference")
        fetchRequest.predicate = NSPredicate(format: "handle == %@", handle as NSNumber)
        
        var cloudAppearancePreferencesArray : [CloudAppearancePreference]
        do {
            cloudAppearancePreferencesArray = try stack.viewContext.fetch(fetchRequest)
            
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
        let fetchRequest = NSFetchRequest<CloudAppearancePreference>(entityName: "CloudAppearancePreference")
        
        var cloudAppearancePreferencesArray: [CloudAppearancePreference]
        do {
            cloudAppearancePreferencesArray = try stack.viewContext.fetch(fetchRequest)
            
            return cloudAppearancePreferencesArray
        } catch let error as NSError {
            MEGALogError("Could not fetch [CloudAppearancePreference] \(error), \(error.userInfo)")
            
            return nil
        }
    }
    
    @objc func deleteCloudAppearancePreference(handle : UInt64) {
        if let cloudAppearancePreference = fetchCloudAppearancePreference(handle: handle) {
            MEGALogDebug("Delete CloudAppearancePreference \(cloudAppearancePreference)")
            stack.viewContext.delete(cloudAppearancePreference)
            
            MEGAStore.shareInstance()?.save(stack.viewContext)
        } else {
            MEGALogError("Failed to delete CloudAppearancePreference \(handle), it does not exist on Core Data.")
        }
    }
    
    @objc func deleteAllCloudAppearancePreferences() {
        guard let cloudAppearancePreferencesArray = fetchCloudAppearancePreferences() else { return }
        
        for cloudAppearancePreference in cloudAppearancePreferencesArray {
            MEGALogDebug("Delete CloudAppearancePreference \(cloudAppearancePreference)")
            stack.viewContext.delete(cloudAppearancePreference)
        }
        
        MEGAStore.shareInstance()?.save(stack.viewContext)
    }
}
