import MEGAData
import MEGADataMock
import MEGADomain
import MEGASdk
import XCTest

final class DeviceCenterRepositoryTests: XCTestCase {
    
    func testRetrieveBackups_successfullyRetrievedBackupInfo_shouldReturnArrayOfBackups() async throws {
        let mockSdk = MockSdk(
            backupInfoList: [
                MockBackupInfo(identifier: 1),
                MockBackupInfo(identifier: 2),
                MockBackupInfo(identifier: 3)
            ]
        )
        let repository = DeviceCenterRepository(sdk: mockSdk)
        let backups = try await repository.backups()
        
        XCTAssertEqual(backups.count, 3)
    }
    
    func testRetrieveBackups_emptyBackupInfoList_shouldThrowNotFoundError() async {
        let mockSdk = MockSdk(megaSetError: .apiEInternal)
        let repository = DeviceCenterRepository(sdk: mockSdk)
        
        do {
            _ = try await repository.backups()
            XCTFail("Expected error to be thrown.")
        } catch {
            XCTAssertTrue(error is GenericErrorEntity)
        }
    }
    
    func testRetrieveBackups_successfullyRetrievedBackupInfoAndDevicesNames_shouldReturnArrayOfBackups() async throws {
        let encodedIdentifier = base64Encode(string: "1234")
        let encodedName = base64Encode(string: "device1")
        let mockSdk = MockSdk(
            backupInfoList: [
                MockBackupInfo(identifier: 1,
                               deviceIdentifier: encodedIdentifier)
            ],
            devices: [
                encodedIdentifier: encodedName
            ]
        )
        let repository = DeviceCenterRepository(sdk: mockSdk)
        let backups = try await repository.backups()
        
        XCTAssertEqual(backups.count, 1)
        
        let device = backups.first(where: {
            $0.device?.name == encodedName.base64URLDecoded
        })
        
        XCTAssertNotNil(device)
    }
    
    private func base64Encode(string: String) -> String {
        string.data(using: .utf8)?.base64EncodedString(options: []) ?? ""
    }
}
