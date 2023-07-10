import MEGAData
import MEGADataMock
import MEGADomain
import MEGASdk
import XCTest

final class DeviceCenterRepositoryTests: XCTestCase {
    
    func testRetrieveDevices_successfullyRetrievedDevices_shouldReturnArrayOfDevices() async {
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
    
    private func base64Encode(string: String) -> String {
        string.data(using: .utf8)?.base64EncodedString(options: []) ?? ""
    }
}
