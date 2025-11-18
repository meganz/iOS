import MEGAAppSDKRepo
import MEGAAppSDKRepoMock
import MEGADomain
import MEGASdk
import Testing

@Suite("Device Center Repository tests")
struct DeviceCenterRepositoryTests {
    static let defaultDeviceId = "1234"
    static let defaultBackupId = 1
    static let defaultRootHandle: HandleEntity = 1
    
    @Suite("Device fetching")
    struct DeviceFetchTests {
        @Test
        func fetchDevicesReturnsAllDevices() async {
            let firstDeviceId = defaultDeviceId
            let secondDeviceId = "5678"
            
            let repository = makeSUT(
                nodes: generateMockNodes(count: 3),
                backupInfoList: [
                    MockBackupInfo(identifier: 1, deviceIdentifier: firstDeviceId, rootHandle: 1),
                    MockBackupInfo(identifier: 2, deviceIdentifier: firstDeviceId, rootHandle: 2),
                    MockBackupInfo(identifier: 3, deviceIdentifier: secondDeviceId, rootHandle: 3)
                ],
                devices: makeEncodedDevices(from: [
                    firstDeviceId: "device1",
                    secondDeviceId: "device2"
                ])
            )
            
            let devices = await repository.fetchUserDevices()
            
            #expect(devices.count == 2)
        }
        
        @Test
        func fetchDevicesWithEmptyDeviceListReturnsEmptyArray() async {
            let repository = makeSUT()
            
            let devices = await repository.fetchUserDevices()
            
            #expect(devices.isEmpty)
        }
        
        @Test
        func fetchDevicesWithoutAssociatedNodeReturnsNoDevices() async {
            let backups = [
                makeBackupInfo(
                    identifier: defaultBackupId,
                    deviceId: defaultDeviceId,
                    rootHandle: defaultRootHandle,
                    timestamp: Date()
                )
            ]
            
            let repository = makeSUT(
                deviceId: defaultDeviceId,
                deviceName: "device1",
                nodes: [],
                backupInfoList: backups
            )
            
            let devices = await repository.fetchUserDevices()
            
            #expect(devices.isEmpty, "Expected no devices when all backups are invalid")
        }
    }
    
    @Suite("Device status from heartbeat")
    struct DeviceStatusOfflineTests {
        @Test(
            arguments: [
                // Greater than one hour -> mobile
                (backupType: MEGABackupType.cameraUpload, interval: 2 * 60 * 60 as TimeInterval),
                // Greater than 30 minutes -> other devices
                (backupType: MEGABackupType.downSync, interval: 45 * 60 as TimeInterval)
            ]
        )
        func deviceWithStaleHeartbeatIsOffline(
            backupType: MEGABackupType,
            interval: TimeInterval
        ) async {
            let repository = makeSUT(
                nodes: generateMockNodes(count: 1),
                backupInfoList: [
                    MockBackupInfo(
                        identifier: 1,
                        deviceIdentifier: defaultDeviceId,
                        rootHandle: 1,
                        backupType: backupType,
                        syncState: .active,
                        backupSubstate: .noSyncError,
                        heartbeatStatus: .upToDate,
                        timestamp: Date(timeIntervalSinceNow: -interval),
                        activityTimestamp: Date(timeIntervalSinceNow: -interval)
                    )
                ],
                devices: makeEncodedDevices(from: [
                    defaultDeviceId: "device1"
                ])
            )
            
            let userDevices = await repository.fetchUserDevices()
            
            #expect(userDevices.count == 1)
            assertThatHasCorrectDeviceStatus(
                on: userDevices,
                expectedStatus: .offline
            )
        }
    }
    
    @Suite("Current device identifier")
    struct DeviceIdTests {
        @Test(arguments: ["device1" as String?, nil])
        func currentDeviceIdMatchesSdkValue(sdkDeviceId: String?) {
            let repository = makeSUT(deviceId: sdkDeviceId)
            
            let loadedDeviceId = repository.loadCurrentDeviceId()
            
            #expect(loadedDeviceId == sdkDeviceId)
        }
    }
    
    @Suite("Backup deduplication")
    struct DeviceBackupsDeduplicationTests {
        @Test(arguments: [true, false])
        func keepsNewestTimestampBackup(latestFirst: Bool) async throws {
            let earlierTimestamp = Date(timeIntervalSinceNow: -120)
            let latestTimestamp = Date()
            
            let orderedTimestamps = latestFirst
            ? [latestTimestamp, earlierTimestamp]
            : [earlierTimestamp, latestTimestamp]
            
            let backups = orderedTimestamps.map {
                makeBackupInfo(
                    identifier: defaultBackupId,
                    deviceId: defaultDeviceId,
                    rootHandle: defaultRootHandle,
                    timestamp: $0
                )
            }
            
            let repository = makeSUT(
                deviceId: defaultDeviceId,
                deviceName: "device1",
                nodes: generateMockNodes(count: 1),
                backupInfoList: backups
            )
            
            let devices = await repository.fetchUserDevices()
            
            #expect(devices.count == 1)
            
            let device = try #require(devices.first, "Expected one device")
            let deduplicatedBackups = try #require(
                device.backups,
                "Expected device to contain backups"
            )
            
            #expect(deduplicatedBackups.count == 1, "Expected only one backup after deduplication")
            #expect(deduplicatedBackups.first?.timestamp == latestTimestamp)
        }
    }
    
    @Suite("Device names")
    struct DeviceNamesTests {
        @Test(
            arguments: [
                (
                    deviceIds: ["1234", "5678"],
                    names: ["device1", "device2"]
                )
            ]
        )
        func fetchDeviceNamesReturnsAllDeviceNames(
            deviceIds: [String],
            names: [String]
        ) async {
            let devicesDictionary = Dictionary(uniqueKeysWithValues: zip(deviceIds, names))
            
            let repository = DeviceCenterRepositoryTests.makeSUT(
                nodes: DeviceCenterRepositoryTests.generateMockNodes(count: deviceIds.count),
                backupInfoList: [
                    MockBackupInfo(identifier: 1, deviceIdentifier: deviceIds[0], rootHandle: 1),
                    MockBackupInfo(identifier: 2, deviceIdentifier: deviceIds[1], rootHandle: 2)
                ],
                devices: DeviceCenterRepositoryTests.makeEncodedDevices(from: devicesDictionary)
            )
            
            let fetchedNames = await repository.fetchDeviceNames()
            
            #expect(fetchedNames.sorted() == names.sorted())
        }
    }
    
    @Suite("Backup sync status mapping")
    struct BackupStatusMappingTests {
        @Test(
            arguments: [
                (syncState: BackUpState.unknown, substate: BackUpSubState.noSyncError, expected: BackupStatusEntity.backupStopped),
                (syncState: .failed, substate: .storageOverquota, expected: .outOfQuota),
                (syncState: .failed, substate: .accountExpired, expected: .blocked),
                (syncState: .pauseDown, substate: .noSyncError, expected: .paused),
                (syncState: .disabled, substate: .noSyncError, expected: .disabled)
            ]
        )
        func syncStateAndSubstateProduceExpectedStatus(
            syncState: BackUpState,
            substate: BackUpSubState,
            expected: BackupStatusEntity
        ) async throws {
            let repository = makeSUT(
                nodes: generateMockNodes(count: 1),
                backupInfoList: [
                    MockBackupInfo(
                        identifier: 1,
                        deviceIdentifier: defaultDeviceId,
                        rootHandle: 1,
                        backupType: .downSync,
                        syncState: syncState,
                        backupSubstate: substate,
                        heartbeatStatus: .upToDate
                    )
                ],
                devices: makeEncodedDevices(from: [
                    defaultDeviceId: "device1"
                ])
            )
            
            let devices = await repository.fetchUserDevices()
            let device = try #require(devices.first, "Expected one device")
            
            #expect(device.status == expected)
        }
    }
    
    private static func base64Encode(string: String) -> String {
        string.data(using: .utf8)?.base64EncodedString(options: []) ?? ""
    }
    
    private static func makeEncodedDevices(from plainDevices: [String: String]) -> [String: String] {
        plainDevices.reduce(into: [String: String]()) { result, entry in
            result[entry.key] = base64Encode(string: entry.value)
        }
    }
    
    private static func assertThatHasCorrectDeviceStatus(
        on devices: [DeviceEntity],
        expectedStatus: BackupStatusEntity? = nil
    ) {
        for (index, userDevice) in devices.enumerated() {
            let backupStatus = userDevice.backups?.findHighestPriorityBackupStatus()
            let statusToCompare = expectedStatus ?? userDevice.status
            
            #expect(
                backupStatus == statusToCompare,
                "Unexpected device status at index \(index)"
            )
        }
    }
    
    private static func makeSUT(
        deviceId: String? = nil,
        deviceName: String? = nil,
        nodes: [MockNode] = [],
        backupInfoList: [MockBackupInfo] = [],
        devices: [String: String]? = nil
    ) -> DeviceCenterRepository {
        var finalDevices = devices ?? [:]
        
        if let deviceId, let deviceName {
            finalDevices[deviceId] = base64Encode(string: deviceName)
        }
        
        let mockSdk = MockSdk(
            nodes: nodes,
            backupInfoList: backupInfoList,
            deviceId: deviceId,
            devices: finalDevices
        )
        
        return DeviceCenterRepository(sdk: mockSdk)
    }
    
    private static func makeBackupInfo(
        identifier: Int,
        deviceId: String,
        rootHandle: HandleEntity,
        timestamp: Date,
        backupType: MEGABackupType = .downSync,
        syncState: BackUpState = .active,
        backupSubstate: BackUpSubState = .noSyncError,
        heartbeatStatus: MEGABackupHeartbeatStatus = .upToDate
    ) -> MockBackupInfo {
        MockBackupInfo(
            identifier: identifier,
            deviceIdentifier: deviceId,
            rootHandle: rootHandle,
            backupType: backupType,
            syncState: syncState,
            backupSubstate: backupSubstate,
            heartbeatStatus: heartbeatStatus,
            timestamp: timestamp,
            activityTimestamp: timestamp
        )
    }
    
    private static func generateMockNodes(count: Int) -> [MockNode] {
        guard count > 0 else { return [] }
        
        return (1...count).map { index in
            MockNode(handle: HandleEntity(index))
        }
    }
}

private extension Sequence where Element == BackupEntity {
    func findHighestPriorityBackupStatus() -> BackupStatusEntity? {
        compactMap {$0.backupStatus}
            .max {$0.priority < $1.priority}
    }
}
