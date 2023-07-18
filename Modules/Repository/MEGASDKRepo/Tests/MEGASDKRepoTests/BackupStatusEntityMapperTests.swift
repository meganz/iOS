import MEGADomain
import MEGASdk
import MEGASDKRepo
import XCTest

class BackupStatusEntityMappingTests: XCTestCase {
    
    func testBackupStatusEntity_highestPriority_shouldReturnTheElementWithHighestPriority() {
        let backupStatuses: [BackupStatusEntity] = [.backupStopped, .outOfQuota, .offline, .initialising, .paused, .updating, .scanning, .noCameraUploads, .error, .upToDate, .disabled, .blocked]
                
        let highestPriorityElement = backupStatuses.max { $0.priority < $1.priority }
        
        XCTAssertEqual(highestPriorityElement, .updating)
    }
    
    func testBackupStatusEntity_onTestingTheListOfStatuses_shouldReturnThePriority() {
        XCTAssertEqual(BackupStatusEntity.noCameraUploads.priority, 0)
        XCTAssertEqual(BackupStatusEntity.backupStopped.priority, 1)
        XCTAssertEqual(BackupStatusEntity.disabled.priority, 2)
        XCTAssertEqual(BackupStatusEntity.offline.priority, 3)
        XCTAssertEqual(BackupStatusEntity.upToDate.priority, 4)
        XCTAssertEqual(BackupStatusEntity.error.priority, 5)
        XCTAssertEqual(BackupStatusEntity.blocked.priority, 6)
        XCTAssertEqual(BackupStatusEntity.outOfQuota.priority, 7)
        XCTAssertEqual(BackupStatusEntity.paused.priority, 8)
        XCTAssertEqual(BackupStatusEntity.initialising.priority, 9)
        XCTAssertEqual(BackupStatusEntity.scanning.priority, 10)
        XCTAssertEqual(BackupStatusEntity.updating.priority, 11)
    }
}
