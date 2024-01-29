import MEGADomain
import XCTest

final class FakeNoItemsToUploadUseCaseTests: XCTestCase {
    func testMonitorUploadStatus_onMonitoring_shouldNotEmitAnyItems() async {
        let sut = FakeNoItemsToUploadUseCase()
        var iterator = sut.monitorUploadStats().makeAsyncIterator()
        
        let uploadComplete = await iterator.next()
        XCTAssertNil(uploadComplete)
    }
}
