import MEGAAppSDKRepo
import MEGAAppSDKRepoMock
import MEGADomain
import MEGASdk
import XCTest

final class DeviceCenterRepositoryBackupStatusesTests: XCTestCase {
    
    /// UpToDate: Backup state is ACTIVE = 1 & Heartbeat status is  UPTODATE = 1
    func testFetchUserDevicesAndBackups_whenDefineUpToDateBackup_shouldReturnUpToDateStatus() async throws {
        try await validateBackupStatusAfterFetching(
            syncState: .active,
            backupHeartbeatStatus: .upToDate,
            expectedBackupStatus: .upToDate
        )
    }
    
    /// Offline: Compare the current time and the the latest heartbeat, if it longer than expected time, it shows offline.
    ///      Web: once the heartbeat  is not detected in 30mins.
    ///      Mobile: once the heartbeat is not detected in 1 hour.
    func testFetchUserDevicesAndBackups_whenDefineOfflineBackup_shouldReturnOfflineStatus() async throws {
        let twoHoursInterval: TimeInterval = 2 * 60 * 60 // Greater than one hour
        
        try await validateBackupStatusAfterFetching(
            backupType: .cameraUpload, // Mobile devices
            syncState: .active,
            backupHeartbeatStatus: .upToDate,
            timestamp: Date(timeIntervalSinceNow: -twoHoursInterval),
            activityTimestamp: Date(timeIntervalSinceNow: -twoHoursInterval),
            expectedBackupStatus: .offline
        )
        
        let fortyFiveMinutesInterval: TimeInterval = 45 * 60 // Greater than 30 minutes
        
        try await validateBackupStatusAfterFetching(
            backupType: .downSync, // Other devices not mobile devices
            syncState: .active,
            backupHeartbeatStatus: .upToDate,
            timestamp: Date(timeIntervalSinceNow: -fortyFiveMinutesInterval),
            activityTimestamp: Date(timeIntervalSinceNow: -fortyFiveMinutesInterval),
            expectedBackupStatus: .offline
        )
    }
    
    /// Error: This state is TEMPORARY_DISABLED = 3 & Heartbeat status is  INACTIVE = 4
    ///      Block: BUSINESS_EXPIRED = 10, ACCOUNT_BLOCKED = 23
    ///      Error: STORAGE_OVERQUOTA = 9,
    func testFetchUserDevicesAndBackups_whenDefineErrorBackup_shouldReturnErrorStatus() async throws {
        try await validateBackupStatusAfterFetching(
            syncState: .temporaryDisabled,
            backupSubstate: .accountExpired,
            backupHeartbeatStatus: .inactive,
            expectedBackupStatus: .blocked
        )
        
        try await validateBackupStatusAfterFetching(
            syncState: .temporaryDisabled,
            backupSubstate: .storageOverquota,
            backupHeartbeatStatus: .inactive,
            expectedBackupStatus: .outOfQuota
        )
    }
    
    /// Disabled: Backup state is DISABLED = 4 & Heartbeat status is  INACTIVE = 4
    func testFetchUserDevicesAndBackups_whenDefineDisabledBackup_shouldReturnDisabledStatus() async throws {
        try await validateBackupStatusAfterFetching(
            syncState: .disabled,
            backupHeartbeatStatus: .inactive,
            expectedBackupStatus: .disabled
        )
    }
    
    /// Paused:
    /// Backup state is PAUSE_UP = 5, (Active but upload transfers paused in the SDK)
    /// Backup state is PAUSE_DOWN = 6,  (Active but download transfers paused in the SDK)
    /// Backup state is PAUSE_FULL = 7,  (Active but transfers paused in the SDK)
    func testFetchUserDevicesAndBackups_whenDefinePausedBackup_shouldReturnPausedStatus() async throws {
        try await validateBackupStatusAfterFetching(
            syncState: .pauseDown,
            backupHeartbeatStatus: .inactive,
            expectedBackupStatus: .paused
        )
        
        try await validateBackupStatusAfterFetching(
            syncState: .pauseUp,
            backupHeartbeatStatus: .inactive,
            expectedBackupStatus: .paused
        )
        
        try await validateBackupStatusAfterFetching(
            syncState: .pauseFull,
            backupHeartbeatStatus: .inactive,
            expectedBackupStatus: .paused
        )
    }
    
    /// Updating... Backup state is ACTIVE = 1 & Heartbeat status is SYNCING = 2
    func testFetchUserDevicesAndBackups_whenDefineUpdatingBackup_shouldReturnUpdatingStatus() async throws {
        try await validateBackupStatusAfterFetching(
            syncState: .active,
            backupHeartbeatStatus: .syncing,
            expectedBackupStatus: .updating
        )
    }
    
    /// Scanning... Backup state is ACTIVE = 1 & Heartbeat status is PENDING = 3
    func testFetchUserDevicesAndBackups_whenDefineScanningBackup_shouldReturnScanningStatus() async throws {
        try await validateBackupStatusAfterFetching(
            syncState: .active,
            backupHeartbeatStatus: .pending,
            expectedBackupStatus: .scanning
        )
    }
    
    /// Initialising... backup state ACTIVE = 1 & heartbeat state is UNKNOWN = 5
    func testFetchUserDevicesAndBackups_whenDefineInitialisingBackup_shouldReturnInitialisingStatus() async throws {
        try await validateBackupStatusAfterFetching(
            syncState: .active,
            backupHeartbeatStatus: .unknown,
            expectedBackupStatus: .initialising
        )
    }
    
    private func validateBackupStatusAfterFetching(
        backupType: BackupTypeEntity = .backupUpload,
        syncState: BackUpStateEntity,
        backupSubstate: BackUpSubStateEntity = .noSyncError,
        backupHeartbeatStatus: BackupHeartbeatStatusEntity,
        timestamp: Date = Date(),
        activityTimestamp: Date = Date(),
        expectedBackupStatus: BackupStatusEntity,
        file: StaticString = #file,
        line: UInt = #line
    ) async throws {
        let sut = makeSUT(
            backupType: backupType,
            syncState: syncState,
            substate: backupSubstate,
            heartbeatStatus: backupHeartbeatStatus,
            timestamp: timestamp,
            activityTimestamp: activityTimestamp
        )
  
        let devices = await sut.fetchUserDevices()
        let currentDevice = try XCTUnwrap(devices.first)
        let currentBackup = try XCTUnwrap(currentDevice.backups?.first)
        let currentBackupStatus = try XCTUnwrap(currentBackup.backupStatus)
        
        XCTAssertEqual(
            currentBackup.backupStatus,
            expectedBackupStatus,
            "Failed to validate backup status. expected: \(expectedBackupStatus), current: \(currentBackupStatus), file: \(file), line: \(line)"
        )
    }
    
    // MARK: - Test Helpers
    
    private func makeSUT(
        backupType: BackupTypeEntity,
        syncState: BackUpStateEntity,
        substate: BackUpSubStateEntity,
        heartbeatStatus: BackupHeartbeatStatusEntity,
        deviceId: String = "1",
        deviceName: String = "device1",
        timestamp: Date,
        activityTimestamp: Date
    ) -> (DeviceCenterRepository) {
        let mockSdk = MockSdk(
            backupInfoList: [
                MockBackupInfo(
                    identifier: 1,
                    deviceIdentifier: deviceId,
                    backupType: backupType.toMEGABackupType(),
                    syncState: syncState.toBackUpState(),
                    backupSubstate: substate.toBackUpSubState(),
                    heartbeatStatus: heartbeatStatus.toMEGABackupHeartbeatStatus(),
                    timestamp: timestamp,
                    activityTimestamp: activityTimestamp
                )
            ],
            devices: [
                deviceId: base64Encode(string: deviceName)
            ]
        )
        return DeviceCenterRepository(sdk: mockSdk)
    }
    
    private func base64Encode(string: String) -> String {
        string.data(using: .utf8)?.base64EncodedString(options: []) ?? ""
    }
}
