@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGASdk
import MEGASDKRepo
import MEGASDKRepoMock
import XCTest

final class ViewModeStoreTests: XCTestCase {
    class Harness {
        let viewModeUserCase: ViewModeStore
        let megaStore = MockMEGAStore()
        var preferenceRepo: MockPreferenceRepository<Int>
        
        init(saved: ViewModePreferenceEntity? = nil) {
            self.preferenceRepo = MockPreferenceRepository<Int>()
            if let saved {
                preferenceRepo[MEGAViewModePreference] = saved.rawValue
            }
            viewModeUserCase = ViewModeStore(
                preferenceRepo: preferenceRepo,
                megaStore: megaStore,
                sdk: MockSdk(),
                notificationCenter: .init()
            )
        }
        
        func viewMode(for node: NodeEntity = NodeEntity(handle: 1)) -> ViewModePreferenceEntity {
            viewModeUserCase.viewMode(for: .node(node))
        }
    }
    
    func test_ReadViewMode_fromPreference_returnsList_ifNothingIsSaved() {
        let mode = Harness().viewMode()
        XCTAssertEqual(mode, .list)
    }
    
    func test_ReadViewMode_fromPreference_returnsThumbnail_ifIsSavedInPrefs() {
        let harness = Harness(saved: .thumbnail)
        XCTAssertEqual(harness.viewMode(), .thumbnail)
    }
    
    func test_ReadViewMode_fromPreference_returnsList_ifIsSavedInPrefs() {
        let harness = Harness(saved: .list)
        XCTAssertEqual(harness.viewMode(), .list)
    }
    
    func test_ReadViewMode_fromMEGAStore_returnsList_ifSavedForNode() {
        let harness = Harness(saved: .perFolder)
        harness.megaStore.viewModes[1] = ViewModePreferenceEntity.list
        XCTAssertEqual(harness.viewMode(), .list)
    }
    
    func test_ReadViewMode_fromMEGAStore_returnsThumbnail_ifSavedForNode() {
        let harness = Harness(saved: .perFolder)
        harness.megaStore.viewModes[1] = ViewModePreferenceEntity.thumbnail
        XCTAssertEqual(harness.viewMode(), .thumbnail)
    }
    
    class MockMEGAStore: MEGAStore {
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
    }
}
