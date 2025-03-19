@testable import DeviceCenter
import MEGADomain
import Testing

@Suite("Backup Status Provider Test Suite - Testing backup status mapping")
struct BackupStatusProviderTestSuite {
    @Test("Returns expected backup status for given backup status entity", arguments: [
        (BackupStatusEntity.upToDate, "upToDate"),
        (BackupStatusEntity.scanning, "updating"),
        (BackupStatusEntity.initialising, "updating"),
        (BackupStatusEntity.updating, "updating"),
        (BackupStatusEntity.noCameraUploads, "noCameraUploads"),
        (BackupStatusEntity.disabled, "disabled"),
        (BackupStatusEntity.offline, "offline"),
        (BackupStatusEntity.backupStopped, "error"),
        (BackupStatusEntity.paused, "paused"),
        (BackupStatusEntity.outOfQuota, "outOfQuota"),
        (BackupStatusEntity.error, "error"),
        (BackupStatusEntity.blocked, "disabled")
    ])
    func returnsExpectedBackupStatusForEntity(
        backupStatusEntity: BackupStatusEntity,
        expectedIconName: String
    ) {
        let provider = BackupStatusProvider()
        guard let backupStatus = provider.backupStatus(for: backupStatusEntity) else {
            Issue.record("Expected a BackupStatus for \(backupStatusEntity)")
            return
        }
        #expect(backupStatus.iconName == expectedIconName, "Expected iconName \(expectedIconName) for status \(backupStatusEntity) but got \(backupStatus.iconName)")
    }
    
    @Test("Backup status dictionary contains a BackupStatus for each defined status", arguments: [
        BackupStatusEntity.upToDate,
        BackupStatusEntity.scanning,
        BackupStatusEntity.initialising,
        BackupStatusEntity.updating,
        BackupStatusEntity.noCameraUploads,
        BackupStatusEntity.disabled,
        BackupStatusEntity.offline,
        BackupStatusEntity.backupStopped,
        BackupStatusEntity.paused,
        BackupStatusEntity.outOfQuota,
        BackupStatusEntity.error,
        BackupStatusEntity.blocked
    ])
    func backupStatusDictionaryContainsStatus(backupStatusEntity: BackupStatusEntity) {
        let provider = BackupStatusProvider()
        #expect(provider.backupStatus(for: backupStatusEntity) != nil,
                "Expected a BackupStatus for \(backupStatusEntity)")
    }
}
