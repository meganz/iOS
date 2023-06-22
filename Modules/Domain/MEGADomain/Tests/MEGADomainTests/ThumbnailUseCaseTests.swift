import MEGADomain
import MEGADomainMock
import XCTest

final class ThumbnailUseCaseTests: XCTestCase {

    func testCachedPreviewOrOriginalPath_onSlideShow_shouldReturnNotNil() throws {
        let sut = MockThumbnailUseCase().cachedPreviewOrOriginalPath(for: NodeEntity(handle: 1))
        XCTAssertNotNil(sut)
    }
}
