@testable import MEGA
import MEGADomain

final class MockMEGAStore: MEGAStore, @unchecked Sendable {
    var deleteOfflineAppearancePreference_calledTimes = 0
    var remove_calledTimes = 0
    private let offlineNode: MOOfflineNode?
    
    lazy var inMemoryContainer: NSPersistentContainer = {
        let description = NSPersistentStoreDescription()
        description.url = URL(fileURLWithPath: "/dev/null")
        let container = NSPersistentContainer(name: "MEGACD")
        container.persistentStoreDescriptions = [description]
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        return container
    }()
    var viewModes: [UInt64: ViewModePreferenceEntity] = [:]
    @objc override func fetchCloudAppearancePreference(handle: UInt64) -> CloudAppearancePreference? {
        let pref = NSEntityDescription.insertNewObject(forEntityName: "CloudAppearancePreference", into: inMemoryContainer.viewContext) as! CloudAppearancePreference
        if let viewMode = viewModes[handle] {
            pref.viewMode = NSNumber(integerLiteral: viewMode.rawValue)
        }
        return pref
    }
    
    var offlineViewModes: [String: ViewModePreferenceEntity] = [:]
    @objc override func fetchOfflineAppearancePreference(path: String) -> OfflineAppearancePreference? {
        
        guard let viewMode = offlineViewModes[path] else {
            return nil
        }
        
        let pref = NSEntityDescription.insertNewObject(forEntityName: "OfflineAppearancePreference", into: inMemoryContainer.viewContext) as! OfflineAppearancePreference
        pref.viewMode = NSNumber(integerLiteral: viewMode.rawValue)
        pref.localPath = path
        return pref
    }
    
    init(offlineNode: MOOfflineNode? = nil) {
        self.offlineNode = offlineNode
    }
    
    override func deleteOfflineAppearancePreference(path: String) {
        deleteOfflineAppearancePreference_calledTimes += 1
    }

    override func remove(_ offlineNode: MOOfflineNode) {
        remove_calledTimes += 1
    }
    
    override func fetchOfflineNode(withPath path: String) -> MOOfflineNode? {
        offlineNode
    }
    
    @objc override func insertOrUpdateOfflineViewMode(path: String, viewMode: Int) {
        offlineViewModes[path] = ViewModePreferenceEntity(rawValue: viewMode)
    }
}
