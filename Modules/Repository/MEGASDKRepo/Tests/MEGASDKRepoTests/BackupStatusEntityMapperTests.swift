import MEGADomain
import MEGASdk
import MEGASDKRepo
import XCTest

final class BackupStatusEntityMappingTests: XCTestCase {
    
    func testBackupStatusEntity_highestPriority_shouldReturnTheElementWithHighestPriority() {
        let backupStatuses: [BackupStatusEntity] = [.backupStopped, .outOfQuota, .offline, .initialising, .paused, .updating, .scanning, .noCameraUploads, .error, .upToDate, .disabled, .blocked, .inactive]
                
        let highestPriorityElement = backupStatuses.max { $0.priority < $1.priority }
        
        XCTAssertEqual(highestPriorityElement, .updating)
    }
    
    func testBackupStatusEntity_onTestingTheListOfStatuses_shouldReturnThePriority() {
        XCTAssertEqual(BackupStatusEntity.inactive.priority, 0)
        XCTAssertEqual(BackupStatusEntity.noCameraUploads.priority, 1)
        XCTAssertEqual(BackupStatusEntity.backupStopped.priority, 2)
        XCTAssertEqual(BackupStatusEntity.disabled.priority, 3)
        XCTAssertEqual(BackupStatusEntity.offline.priority, 4)
        XCTAssertEqual(BackupStatusEntity.upToDate.priority, 5)
        XCTAssertEqual(BackupStatusEntity.error.priority, 6)
        XCTAssertEqual(BackupStatusEntity.blocked.priority, 7)
        XCTAssertEqual(BackupStatusEntity.outOfQuota.priority, 8)
        XCTAssertEqual(BackupStatusEntity.paused.priority, 9)
        XCTAssertEqual(BackupStatusEntity.initialising.priority, 10)
        XCTAssertEqual(BackupStatusEntity.scanning.priority, 11)
        XCTAssertEqual(BackupStatusEntity.updating.priority, 12)
    }
}
