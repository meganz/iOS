@testable import MEGA
import MEGADomain

final class MockMEGAStore: MEGAStore, @unchecked Sendable {
    private(set) var deleteOfflineAppearancePreference_calledTimes = 0
    private(set) var remove_calledTimes = 0
    private(set) var removeAllOfflineNodes_calledTimes = 0
    private(set) var insertOfflineNode_calledTimes = 0
    private(set) var removeAllUploadTransfers_calledTimes = 0
    
    var insertOfflineNode_lastPath: String?
    
    private let fetchOfflineNodes: [MOOfflineNode]?
    private let offlineNode: MOOfflineNode?
    private var uploads: [TransferRecordDTO]?
    
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
    var offlineViewModes: [String: ViewModePreferenceEntity] = [:]
    
    init(
        fetchOfflineNodes: [MOOfflineNode]? = nil,
        offlineNode: MOOfflineNode? = nil,
        uploads: [TransferRecordDTO]? = nil
    ) {
        self.fetchOfflineNodes = fetchOfflineNodes
        self.offlineNode = offlineNode
        self.uploads = uploads
    }
    
    @objc override func fetchCloudAppearancePreference(handle: UInt64) -> CloudAppearancePreference? {
        let pref = NSEntityDescription.insertNewObject(
            forEntityName: "CloudAppearancePreference",
            into: inMemoryContainer.viewContext
        ) as! CloudAppearancePreference
        
        if let viewMode = viewModes[handle] {
            pref.viewMode = NSNumber(integerLiteral: viewMode.rawValue)
        }
        return pref
    }
    
    @objc override func fetchOfflineAppearancePreference(path: String) -> OfflineAppearancePreference? {
        guard let viewMode = offlineViewModes[path] else { return nil }
        
        let pref = NSEntityDescription.insertNewObject(
            forEntityName: "OfflineAppearancePreference",
            into: inMemoryContainer.viewContext
        ) as! OfflineAppearancePreference
        
        pref.viewMode = NSNumber(integerLiteral: viewMode.rawValue)
        pref.localPath = path
        return pref
    }
    
    override func deleteOfflineAppearancePreference(path: String) {
        deleteOfflineAppearancePreference_calledTimes += 1
    }
    
    override func fetchOfflineNodes(_ maxItems: NSNumber?, inRootFolder: Bool) -> [MOOfflineNode]? {
        fetchOfflineNodes
    }
    
    override func fetchOfflineNode(withPath path: String) -> MOOfflineNode? {
        offlineNode
    }
    
    override func remove(_ offlineNode: MOOfflineNode) {
        remove_calledTimes += 1
    }
    
    override func removeAllOfflineNodes() {
        removeAllOfflineNodes_calledTimes += 1
    }
    
    @objc override func insertOrUpdateOfflineViewMode(path: String, viewMode: Int) {
        offlineViewModes[path] = ViewModePreferenceEntity(rawValue: viewMode)
    }
    
    override func offlineNode(with node: MEGANode) -> MOOfflineNode? {
        offlineNode
    }
    
    override func offlineNode(withHandle base64Handle: String) -> MOOfflineNode? {
        offlineNode
    }
    
    override func insertOfflineNode(_ node: MEGANode, api: MEGASdk, path: String) {
        insertOfflineNode_calledTimes += 1
        insertOfflineNode_lastPath = path
    }
    
    @objc override func fetchUploadTransfers() -> [TransferRecordDTO]? {
        uploads
    }
    
    @objc override func removeAllUploadTransfers() {
        removeAllUploadTransfers_calledTimes += 1
    }
}
