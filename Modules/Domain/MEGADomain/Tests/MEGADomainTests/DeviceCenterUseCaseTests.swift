import MEGADomain
import MEGADomainMock
import XCTest

final class DeviceCenterUseCaseTests: XCTestCase {
    
    func testRetrieveBackups_successfullyRetrievedBackupInfo_shouldReturnArrayOfBackups() async throws {
        let expectedBackupInfoEntities = [BackupEntity(id: 1),
                                          BackupEntity(id: 2),
                                          BackupEntity(id: 3)]
        let mockRepository = MockDeviceCenterRepository(backupEntities: expectedBackupInfoEntities)
        let sut = DeviceCenterUseCase(deviceCenterRepository: mockRepository)
            
        let result = try await sut.backups()
        XCTAssertEqual(result, expectedBackupInfoEntities)
    }
    
    func testRetrieveBackups_onEmptyArray_shouldThrowGenericError() async {
        let mockRepository = MockDeviceCenterRepository(shouldFailRequest: true)
        let sut = DeviceCenterUseCase(deviceCenterRepository: mockRepository)
        
        do {
           _ = try await sut.backups()
           XCTFail("Expected error to be thrown.")
        } catch {
            XCTAssertTrue(error is GenericErrorEntity, "Expected GenericErrorEntity to be thrown.")
        }
    }
}
