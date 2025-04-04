import MEGAAppSDKRepo
import MEGAAppSDKRepoMock
import MEGADomain
import MEGASdk
import XCTest

final class DeviceCenterRepositoryTests: XCTestCase {
    
    func testFetchDevices_successfullyRetrievedDevices_shouldReturnArrayOfDevices() async {
        let id1 = "1234"
        let id2 = "5678"
        let encodedName1 = base64Encode(string: "device1")
        let encodedName2 = base64Encode(string: "device2")
        let mockSdk = MockSdk(
            backupInfoList: [
                MockBackupInfo(identifier: 1, deviceIdentifier: id1),
                MockBackupInfo(identifier: 2, deviceIdentifier: id1),
                MockBackupInfo(identifier: 3, deviceIdentifier: id2)
            ],
            devices: [
                id1: encodedName1,
                id2: encodedName2
            ]
        )
        
        let repository = DeviceCenterRepository(sdk: mockSdk)
        let devices = await repository.fetchUserDevices()
        
        XCTAssertEqual(devices.count, 2)
    }
    
    func testRetrieveDevices_emptyDeviceList_shouldReturnEmptyArray() async {
        let mockSdk = MockSdk()
        let repository = DeviceCenterRepository(sdk: mockSdk)

        let devices = await repository.fetchUserDevices()
        XCTAssertTrue(devices.isEmpty)
    }
    
    func testFetchDevices_validBackupInfoAndDevices_shouldReturnDevicesWithCorrectStatus(file: StaticString = #filePath, line: UInt = #line) async throws {
        let id1 = "1234"
        let encodedName1 = base64Encode(string: "device1")
        let mockSdk = MockSdk(
            backupInfoList: generateRandomBackupInfo(count: Int.random(in: 1...10), deviceId: id1),
            devices: [
                id1: encodedName1
            ]
        )
        
        let mockRepository = DeviceCenterRepository(sdk: mockSdk)
        let userDevices = await mockRepository.fetchUserDevices()
        
        XCTAssertEqual(userDevices.count, 1)
        
        assertThatHasCorrectDeviceStatus(on: userDevices)
    }
    
    func testFetchMobileDevices_validBackupWithTheLastIteractionMoreThanAnHourAgo_shouldReturnOfflineStatus() async {
        let id1 = "1234"
        let encodedName1 = base64Encode(string: "device1")
        let twoHoursInterval: TimeInterval = 2 * 60 * 60  // Greater than one hour
        let mockSdk = MockSdk(
            backupInfoList: [
                MockBackupInfo(
                    identifier: 1,
                    deviceIdentifier: id1,
                    backupType: .cameraUpload, // Mobile devices
                    syncState: .active,
                    backupSubstate: .noSyncError,
                    heartbeatStatus: .upToDate,
                    timestamp: Date(timeIntervalSinceNow: -twoHoursInterval),
                    activityTimestamp: Date(timeIntervalSinceNow: -twoHoursInterval)
                )
            ],
            devices: [
                id1: encodedName1
            ]
        )
        
        let mockRepository = DeviceCenterRepository(sdk: mockSdk)
        let userDevices = await mockRepository.fetchUserDevices()
        
        XCTAssertEqual(userDevices.count, 1)
        
        assertThatHasCorrectDeviceStatus(on: userDevices, expectedStatus: .offline)
    }
    
    func testFetchOtherDevices_validBackupWithTheLastIteractionMoreThanHalfAnHourAgo_shouldReturnOfflineStatus() async {
        let id1 = "1234"
        let encodedName1 = base64Encode(string: "device1")
        let fortyFiveInterval: TimeInterval = 45 * 60 // Greater than 30 minutes
        let mockSdk = MockSdk(
            backupInfoList: [
                MockBackupInfo(
                    identifier: 1,
                    deviceIdentifier: id1,
                    backupType: .downSync, // Other devices not mobile devices
                    syncState: .active,
                    backupSubstate: .noSyncError,
                    heartbeatStatus: .upToDate,
                    timestamp: Date(timeIntervalSinceNow: -fortyFiveInterval),
                    activityTimestamp: Date(timeIntervalSinceNow: -fortyFiveInterval)
                )
            ],
            devices: [
                id1: encodedName1
            ]
        )
        
        let mockRepository = DeviceCenterRepository(sdk: mockSdk)
        let userDevices = await mockRepository.fetchUserDevices()
        
        XCTAssertEqual(userDevices.count, 1)
        
        assertThatHasCorrectDeviceStatus(on: userDevices, expectedStatus: .offline)
    }
    
    func testDeviceId_currentDeviceId_shouldReturnTheSameString() {
        let deviceId = "device1"
        let mockSdk = MockSdk(deviceId: deviceId)
        let repository = DeviceCenterRepository(sdk: mockSdk)
        
        XCTAssertEqual(repository.loadCurrentDeviceId(), deviceId)
    }
    
    func testDeviceId_nilDeviceId_shouldReturnNil() {
        let mockSdk = MockSdk()
        let repository = DeviceCenterRepository(sdk: mockSdk)
        
        XCTAssertNil(repository.loadCurrentDeviceId())
    }
    
    private func base64Encode(string: String) -> String {
        string.data(using: .utf8)?.base64EncodedString(options: []) ?? ""
    }
    
    private func generateRandomBackupInfo(count: Int, deviceId: String) -> [MockBackupInfo] {
        var mockBackupInfoArray = [MockBackupInfo]()
        
        for index in 1...count {
            let identifier = index
            let deviceIdentifier = deviceId
            let backupType = MEGABackupType(rawValue: Int.random(in: -1...5)) ?? .invalid
            let syncState = BackUpState(rawValue: Int.random(in: 0...9)) ?? .unknown
            let backupSubstate = syncState == .failed || syncState == .temporaryDisabled ? BackUpSubState(rawValue: Int.random(in: 0...45)) ?? .noSyncError : .noSyncError
            let heartbeatStatus = MEGABackupHeartbeatStatus(rawValue: UInt(Int.random(in: 1...6))) ?? .unknown
            
            let mockBackupInfo = MockBackupInfo(
                identifier: identifier,
                deviceIdentifier: deviceIdentifier,
                backupType: backupType,
                syncState: syncState,
                backupSubstate: backupSubstate,
                heartbeatStatus: heartbeatStatus
            )
            
            mockBackupInfoArray.append(mockBackupInfo)
        }
        
        return mockBackupInfoArray
    }
    
    func assertThatHasCorrectDeviceStatus(on devices: [DeviceEntity], expectedStatus: BackupStatusEntity? = nil, file: StaticString = #filePath, line: UInt = #line) {
        for(index, userDevice) in devices.enumerated() {
            let deviceBackupStatus = userDevice.backups?.findHighestPriorityBackupStatus()
            
            var deviceExpectedStatus = expectedStatus
            
            if deviceExpectedStatus == nil {
                deviceExpectedStatus = try? XCTUnwrap(userDevice.status, "failed to get device status at: \(index)", file: file, line: line)
            }
                
            XCTAssertEqual(deviceBackupStatus, deviceExpectedStatus, "expect to have equal device status, but failed at index: \(index)", file: file, line: line)
        }
    }
}

private extension Sequence where Element == BackupEntity {
    func findHighestPriorityBackupStatus() -> BackupStatusEntity? {
        compactMap {$0.backupStatus}
            .max {$0.priority < $1.priority}
    }
}
