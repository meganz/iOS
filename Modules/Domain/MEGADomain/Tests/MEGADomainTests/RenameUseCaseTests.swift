import MEGADomain
import MEGADomainMock
import XCTest

final class RenameUseCaseTests: XCTestCase {
    let device1Identifier = "1"
    
    func testRenameDevice_successfulRename_NewNameIsSet() async throws {
        let mock = MockRenameRepository()
        let sut = RenameUseCase(renameRepository: mock)
                                
        try await sut.renameDevice(device1Identifier, newName: "newName")
        
        let data = mock.renamedDeviceRequests
        
        let sortedUpdatedDevices = Dictionary(grouping: data, by: \.deviceId)
        let updatedDevice = try XCTUnwrap(sortedUpdatedDevices[device1Identifier]?.first)
        
        XCTAssertEqual(updatedDevice.deviceId, device1Identifier)
        XCTAssertEqual(updatedDevice.name, "newName")
    }
}
