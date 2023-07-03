import MEGAData
import MEGASdk
import XCTest

class SyncStateMappingTests: XCTestCase {
    
    func testSyncStateEntity_OnUpdateState_shouldReturnCorrectMapping() {
        let sut: [MEGASyncState] = [.notInitialized, .upToDate, .syncing, .pending, .inactive, .unknown]
        
        for type in sut {
            switch type {
            case .notInitialized: XCTAssertEqual(type.toSyncStateEntity(), .notInitialized)
            case .upToDate: XCTAssertEqual(type.toSyncStateEntity(), .upToDate)
            case .syncing: XCTAssertEqual(type.toSyncStateEntity(), .syncing)
            case .pending: XCTAssertEqual(type.toSyncStateEntity(), .pending)
            case .inactive: XCTAssertEqual(type.toSyncStateEntity(), .inactive)
            case .unknown: XCTAssertEqual(type.toSyncStateEntity(), .unknown)
            default: break
            }
        }
    }
}
