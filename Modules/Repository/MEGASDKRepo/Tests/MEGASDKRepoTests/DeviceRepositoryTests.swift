import MEGASDKRepo
import MEGASDKRepoMock
import XCTest

final class DeviceRepositoryTests: XCTestCase {
    let validDeviceId = "123"
    let invalidDeviceId = "invalid123"
    let defaultDeviceName = "iPhone 13 Pro Max"
    let newDeviceName = "iPad Pro 2020"
    let mockError = MockError(errorType: .apiENoent)

    private func makeSUT(
        deviceName: String? = nil,
        error: MockError = MockError(errorType: .apiOk)
    ) -> DeviceRepository {
        let result: MockSdkRequestResult
        
        if let deviceName {
            result = .success(MockRequest(handle: 1, name: deviceName))
        } else {
            result = .failure(error)
        }
        
        let sdk = MockSdk(requestResult: result)
        return DeviceRepository(sdk: sdk)
    }
    
    private func performFailureTest(
        failureMessage: String,
        action: @escaping (DeviceRepository) async throws -> Void
    ) async {
        let sut = makeSUT(error: mockError)
        do {
            try await action(sut)
            XCTFail(failureMessage)
        } catch {
            assertError(error, equals: mockError)
        }
    }

    private func assertError(
        _ error: any Error,
        equals expectedError: MockError,
        in file: StaticString = #filePath,
        line: UInt = #line
    ) {
        if let error = error as? MockError {
            XCTAssertEqual(error, expectedError, "Expected \(expectedError), got \(error)", file: file, line: line)
        } else {
            XCTFail("Expected error of type MockError but got \(type(of: error))", file: file, line: line)
        }
    }

    func testFetchDeviceName_validDeviceId_shouldReturnCorrectDeviceName() async {
        let sut = makeSUT(deviceName: defaultDeviceName)
        
        do {
            let deviceName = try await sut.fetchDeviceName(validDeviceId)
            XCTAssertEqual(deviceName, defaultDeviceName, "Device name should match the expected value.")
        } catch {
            XCTFail("Fetching device name should not throw an error for valid input.")
        }
    }

    func testFetchDeviceName_invalidDeviceId_shouldThrowError() async {
        await performFailureTest(failureMessage: "Fetching device name should fail for invalid device id.") { sut in
            _ = try await sut.fetchDeviceName(self.invalidDeviceId)
        }
    }

    func testRenameDevice_validDeviceIdAndName_shouldSucceed() async {
        let sut = makeSUT(deviceName: defaultDeviceName)

        do {
            try await sut.renameDevice(validDeviceId, newName: newDeviceName)
        } catch {
            XCTFail("Renaming device should not throw an error for valid device id and name.")
        }
    }

    func testRenameDevice_invalidDeviceId_shouldThrowError() async {
        await performFailureTest(failureMessage: "Renaming device should fail for invalid device id.") { sut in
            try await sut.renameDevice(
                self.invalidDeviceId,
                newName: self.newDeviceName
            )
        }
    }
}
