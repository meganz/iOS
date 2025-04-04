import MEGADomain
import MEGADomainMock
import XCTest

final class DeviceUseCaseTests: XCTestCase {
    let defaultDeviceId = "device123"
    let defaultName = "Device Name"
    let defaultNewName = "New Device Name"
    
    private func makeSUT(
        currentDeviceName: String? = nil,
        deviceName: String? = nil,
        renameError: (any Error)? = nil
    ) -> (sut: DeviceUseCase<MockDeviceRepository>, repository: MockDeviceRepository) {
        let repository = MockDeviceRepository(
            currentDeviceName: currentDeviceName,
            deviceName: deviceName,
            renameError: renameError
        )
        let sut = DeviceUseCase(repository: repository)
        
        return (sut, repository)
   }

   func testFetchDeviceName_withValidId_returnsDeviceName() async {
       let expectedDeviceName = defaultName
       let (sut, _) = makeSUT(deviceName: defaultName)
       do {
           let deviceName = try await sut.fetchDeviceName(defaultDeviceId)
           XCTAssertEqual(deviceName, expectedDeviceName, "Device name should match the device name provided")
       } catch {
           XCTFail("Fetching device name should not have failed")
       }
   }

   func testFetchDeviceName_withNilId_returnsNil() async {
       let (sut, _) = makeSUT()
       do {
           let deviceName = try await sut.fetchDeviceName(nil)
           XCTAssertNil(deviceName, "Device name should be nil when device ID is nil")
       } catch {
           XCTFail("Fetching device name should not have failed")
       }
   }
    
    func testFetchCurrentDeviceName_returnsDeviceName() async {
        let expectedDeviceName = defaultName
        let (sut, _) = makeSUT(currentDeviceName: expectedDeviceName)
        do {
            let deviceName = try await sut.fetchCurrentDeviceName()
            XCTAssertEqual(deviceName, expectedDeviceName, "Device name should match the device name provided")
        } catch {
            XCTFail("Fetching current device name should not have failed")
        }
    }

   func testRenameDevice_withValidParameters_doesNotThrowError() async {
       let (sut, _) = makeSUT(deviceName: defaultName)
       do {
           try await sut.renameDevice(
            defaultDeviceId,
            newName: defaultNewName
           )
       } catch {
           XCTFail("Renaming device should not have failed: \(error)")
       }
   }
    
    func testRenameCurrentDevice_withValidParameters_doesNotThrowError() async {
        let (sut, _) = makeSUT(deviceName: defaultName)
        do {
            try await sut.renameCurrentDevice(
             newName: defaultNewName
            )
        } catch {
            XCTFail("Renaming the current device should not have failed: \(error)")
        }
    }

   func testRenameDevice_withExpectedError_throwsError() async {
       let expectedError = NSError(domain: "Test", code: 1, userInfo: nil)
       let (sut, _) = makeSUT(
        deviceName: defaultName,
        renameError: expectedError
       )
       do {
           try await sut.renameDevice(defaultDeviceId, newName: defaultNewName)
           XCTFail("Renaming device should have failed")
       } catch {
           XCTAssertEqual(error as NSError, expectedError, "Error should match the expected error")
       }
   }
}
