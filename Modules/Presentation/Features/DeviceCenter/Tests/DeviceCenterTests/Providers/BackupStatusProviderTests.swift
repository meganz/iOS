@testable import DeviceCenter
import MEGADomain
import Testing

@Suite("Backup Status Provider Test Suite - Testing backup status mapping")
struct BackupStatusProviderTestSuite {
    // MARK: - Backup Display Assets Tests
    @Test("Returns expected backup display assets for given backup display status entity", arguments: [
        (BackupDisplayStatusEntity.upToDate, "upToDate"),
        (.updating, "updating"),
        (.paused, "paused"),
        (.disabled, "disabled"),
        (.error, "error"),
        (.inactive, "inactive")
    ])
    func returnsExpectedBackupDisplayAssetsForEntity(
        backupDisplayStatusEntity: BackupDisplayStatusEntity,
        expectedIconName: String
    ) {
        let provider = BackupStatusProvider()
        guard let assets = provider.backupDisplayAssets(for: backupDisplayStatusEntity) else {
            Issue.record("Expected StatusAssets for \(backupDisplayStatusEntity)")
            return
        }
        #expect(assets.iconName == expectedIconName,
                "Expected iconName \(expectedIconName) for status \(backupDisplayStatusEntity) but got \(assets.iconName)")
    }
    
    @Test("Backup display assets dictionary contains assets for each defined backup display status", arguments: [
        BackupDisplayStatusEntity.upToDate,
        .updating,
        .paused,
        .disabled,
        .error,
        .inactive
    ])
    func backupDisplayAssetsDictionaryContainsStatus(backupDisplayStatusEntity: BackupDisplayStatusEntity) {
        let provider = BackupStatusProvider()
        #expect(provider.backupDisplayAssets(for: backupDisplayStatusEntity) != nil,
                "Expected StatusAssets for \(backupDisplayStatusEntity)")
    }
    
    // MARK: - Device Display Assets Tests
    @Test("Returns expected device display assets for given device display status entity", arguments: [
        (DeviceDisplayStatusEntity.inactive, "inactive"),
        (.attentionNeeded, "attentionNeeded"),
        (.updating, "updating"),
        (.upToDate, "upToDate")
    ])
    func returnsExpectedDeviceDisplayAssetsForEntity(
        deviceDisplayStatusEntity: DeviceDisplayStatusEntity,
        expectedIconName: String
    ) {
        let provider = BackupStatusProvider()
        guard let assets = provider.deviceDisplayAssets(for: deviceDisplayStatusEntity) else {
            Issue.record("Expected StatusAssets for \(deviceDisplayStatusEntity)")
            return
        }
        #expect(assets.iconName == expectedIconName,
                "Expected iconName \(expectedIconName) for device status \(deviceDisplayStatusEntity) but got \(assets.iconName)")
    }
    
    @Test("Device display assets dictionary contains assets for each defined device display status", arguments: [
        DeviceDisplayStatusEntity.inactive,
        .attentionNeeded,
        .updating,
        .upToDate
    ])
    func deviceDisplayAssetsDictionaryContainsStatus(deviceDisplayStatusEntity: DeviceDisplayStatusEntity) {
        let provider = BackupStatusProvider()
        #expect(provider.deviceDisplayAssets(for: deviceDisplayStatusEntity) != nil,
                "Expected StatusAssets for \(deviceDisplayStatusEntity)")
    }
}
