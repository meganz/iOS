
import Foundation

extension MEGAStore {
    
    @objc func insertOrUpdateOfflineSortType(path: String, sortType: Int) {
        if let offlineAppearancePreference = fetchOfflineAppearancePreference(path: path) {
            offlineAppearancePreference.sortType = NSNumber.init(value: sortType)
        } else {
            let offlineAppearancePreference = NSEntityDescription.insertNewObject(forEntityName: "OfflineAppearancePreference", into: storeStack.viewContext) as! OfflineAppearancePreference
            offlineAppearancePreference.localPath = path
            offlineAppearancePreference.sortType = NSNumber.init(value: sortType)
        }
        
        MEGAStore.shareInstance()?.save(storeStack.viewContext)
    }
    
    @objc func insertOrUpdateOfflineViewMode(path: String, viewMode: Int) {
        if let offlineAppearancePreference = fetchOfflineAppearancePreference(path: path) {
            offlineAppearancePreference.viewMode = NSNumber.init(value: viewMode)
        } else {
            let offlineAppearancePreference = NSEntityDescription.insertNewObject(forEntityName: "OfflineAppearancePreference", into: storeStack.viewContext) as! OfflineAppearancePreference
            offlineAppearancePreference.localPath = path
            offlineAppearancePreference.viewMode = NSNumber.init(value: viewMode)
        }
        
        MEGAStore.shareInstance()?.save(storeStack.viewContext)
    }
    
    @objc func fetchOfflineAppearancePreference(path: String) -> OfflineAppearancePreference? {
        let fetchRequest = NSFetchRequest<OfflineAppearancePreference>(entityName: "OfflineAppearancePreference")
        fetchRequest.predicate = NSPredicate(format: "localPath == %@", path)
        
        var offlineAppearancePreferencesArray : [OfflineAppearancePreference]
        do {
            offlineAppearancePreferencesArray = try storeStack.viewContext.fetch(fetchRequest)
            
            guard let offlineAppearancePreference = offlineAppearancePreferencesArray.first else {
                return nil
            }
            
            return offlineAppearancePreference
        } catch let error as NSError {
            MEGALogError("Could not fetch [OfflineAppearancePreference] \(error)")
            
            return nil
        }
    }
    
    @objc func fetchOfflineAppearancePreferences() -> [OfflineAppearancePreference]? {
        let fetchRequest = NSFetchRequest<OfflineAppearancePreference>(entityName: "OfflineAppearancePreference")
        
        var offlineAppearancePreferencesArray : [OfflineAppearancePreference]
        do {
            offlineAppearancePreferencesArray = try storeStack.viewContext.fetch(fetchRequest)
            
            return offlineAppearancePreferencesArray
        } catch let error as NSError {
            MEGALogError("Could not fetch [OfflineAppearancePreference] \(error), \(error.userInfo)")
            
            return nil
        }
    }
    
    @objc func deleteOfflineAppearancePreference(path : String) {
        if let offlineAppearancePreference = fetchOfflineAppearancePreference(path: path) {
            MEGALogDebug("Deleted OfflineAppearancePreference \(offlineAppearancePreference)")
            storeStack.viewContext.delete(offlineAppearancePreference)
            
            MEGAStore.shareInstance()?.save(storeStack.viewContext)
        }
    }
    
    @objc func deleteOfflineAppearancePreferences() {
        guard let offlineAppearancePreferencesArray = fetchOfflineAppearancePreferences() else { return }
        
        for offlineAppearancePreference in offlineAppearancePreferencesArray {
            MEGALogDebug("Delete OfflineAppearancePreference \(offlineAppearancePreference)")
            storeStack.viewContext.delete(offlineAppearancePreference)
        }
    }
}
