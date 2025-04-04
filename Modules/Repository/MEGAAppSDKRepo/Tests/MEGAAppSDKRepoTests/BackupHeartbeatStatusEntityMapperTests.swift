import MEGAAppSDKRepo
import MEGASdk
import XCTest

final class BackupHeartbeatStatusMappingTests: XCTestCase {
    
    func testBackupHeartbeatStatusEntity_OnUpdateStatus_shouldReturnCorrectMapping() {
        let sut: [MEGABackupHeartbeatStatus] = [.upToDate, .syncing, .pending, .inactive, .unknown]
        
        for type in sut {
            switch type {
            case .upToDate: XCTAssertEqual(type.toBackupHeartbeatStatusEntity(), .upToDate)
            case .syncing: XCTAssertEqual(type.toBackupHeartbeatStatusEntity(), .syncing)
            case .pending: XCTAssertEqual(type.toBackupHeartbeatStatusEntity(), .pending)
            case .inactive: XCTAssertEqual(type.toBackupHeartbeatStatusEntity(), .inactive)
            case .unknown: XCTAssertEqual(type.toBackupHeartbeatStatusEntity(), .unknown)
            default: break

            }
        }
    }
}
