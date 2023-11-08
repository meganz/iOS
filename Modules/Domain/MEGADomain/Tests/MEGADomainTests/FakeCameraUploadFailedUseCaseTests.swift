import MEGADomain
import XCTest

final class FakeCameraUploadFailedUseCaseTests: XCTestCase {
    func testMonitorUploadStatus_onMonitoring_shouldEmitError() async {
        let sut = FakeCameraUploadFailedUseCase()
        var iterator = sut.monitorUploadStatus.makeAsyncIterator()
        
        let nextValue = await iterator.next()
        switch nextValue {
        case .failure(let error):
            XCTAssertTrue(error is GenericErrorEntity)
        case .success, .none:
            XCTFail("Unexpected result")
        }
        
        let uploadComplete = await iterator.next()
        XCTAssertNil(uploadComplete)
    }
}
