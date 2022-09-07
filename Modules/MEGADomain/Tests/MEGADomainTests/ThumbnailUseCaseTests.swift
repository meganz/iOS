import XCTest
import MEGADomain
import MEGADomainMock

final class ThumbnailUseCaseTests: XCTestCase {

    func testCachedPreviewOrOriginalPath_onSlideShow_shouldReturnNil() throws {
        let sut = MockThumbnailUseCase().cachedPreviewOrOriginalPath(for: NodeEntity(handle: 1))
        XCTAssertNil(sut)
    }
}
