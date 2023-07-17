import MEGASdk
import MEGASDKRepo
import XCTest

class SyncStateMappingTests: XCTestCase {
    
    func testSyncStateEntity_OnUpdateState_shouldReturnCorrectMapping() {
        let sut: [MEGASyncState] = [.notInitialized, .active, .failed, .temporaryDisabled, .disabled, .pauseUp, .pauseDown, .pauseFull, .deleted, .unknown]
        
        for type in sut {
            switch type {
            case .notInitialized: XCTAssertEqual(type.toSyncStateEntity(), .notInitialized)
            case .active: XCTAssertEqual(type.toSyncStateEntity(), .active)
            case .failed: XCTAssertEqual(type.toSyncStateEntity(), .failed)
            case .temporaryDisabled: XCTAssertEqual(type.toSyncStateEntity(), .temporaryDisabled)
            case .disabled: XCTAssertEqual(type.toSyncStateEntity(), .disabled)
            case .pauseUp: XCTAssertEqual(type.toSyncStateEntity(), .pauseUp)
            case .pauseDown: XCTAssertEqual(type.toSyncStateEntity(), .pauseDown)
            case .pauseFull: XCTAssertEqual(type.toSyncStateEntity(), .pauseFull)
            case .deleted: XCTAssertEqual(type.toSyncStateEntity(), .deleted)
            case .unknown: XCTAssertEqual(type.toSyncStateEntity(), .unknown)
            default: break

            }
        }
    }
}
