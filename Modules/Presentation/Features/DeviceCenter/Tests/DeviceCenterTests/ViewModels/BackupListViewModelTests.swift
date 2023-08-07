@testable import DeviceCenter
import DeviceCenterMocks
import MEGADomain
import MEGADomainMock
import XCTest

final class BackupListViewModelTests: XCTestCase {
    
    func test_loadAssets_matchesBackupStatuses() {
        var backup = BackupEntity(id: 1, name: "backup1")
        let viewModel = makeSUT(backups: [backup])
        
        for status in backupStatusEntities() {
            backup.backupStatus = status
            validateCurrentStatus(viewModel, backup)
        }
    }
    
    func testLoadBackupsModels_backupsWithDifferentStatus_loadsBackupModels() {
        var backup1 = BackupEntity(id: 1, name: "backup1")
        backup1.backupStatus = .updating
        var backup2 = BackupEntity(id: 2, name: "backup2")
        backup2.backupStatus = .upToDate
        
        let viewModel = makeSUT(backups: [backup1, backup2])
        viewModel.loadBackupsModels()
        
        XCTAssertEqual(viewModel.backupModels.count, 2)
    }
    
    private func backupStatusEntities() -> [BackupStatusEntity] {
        [.upToDate, .offline, .blocked, .outOfQuota, .error, .disabled, .paused, .updating, .scanning, .initialising, .backupStopped, .noCameraUploads]
    }
    
    private func backupTypeEntities() -> [BackupTypeEntity] {
        [.backupUpload, .cameraUpload, .mediaUpload, .twoWay, .downSync, .upSync, .invalid]
    }
    
    private func validateCurrentStatus(_ viewModel: BackupListViewModel, _ backupEntity: BackupEntity) {
        let assets = viewModel.loadAssets(for: backupEntity)
        XCTAssertNotNil(assets)
        XCTAssertEqual(assets?.backupStatus.status, backupEntity.backupStatus)
    }
    
    private func makeSUT(backups: [BackupEntity], file: StaticString = #file, line: UInt = #line) -> BackupListViewModel {
        let backupStatusEntities = backupStatusEntities()
        let backupTypeEntities = backupTypeEntities()
        let sut = BackupListViewModel(
            router: MockBackupListViewRouter(),
            backups: backups,
            backupListAssets:
                BackupListAssets(
                    backupTypes: backupTypeEntities.compactMap { BackupType(type: $0) }
                ),
            backupStatuses: backupStatusEntities.compactMap { BackupStatus(status: $0) }
        )
        
        trackForMemoryLeaks(on: sut, file: file, line: line)
        return sut
    }
}
