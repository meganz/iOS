import XCTest
import MEGADomain
@testable import MEGA

final class ThumbnailRepositoryTests: XCTestCase {
    private func repo() -> MockThumbnailRepository {
        MockThumbnailRepository()
    }
    
    private func nodeEntity() -> NodeEntity {
        NodeEntity(handle: 1)
    }
    
    func testHasCachedThumbnail_onCloudDrive_shouldReturnFalse() throws {
        XCTAssertFalse(repo().hasCachedThumbnail(for: nodeEntity(), type: .thumbnail))
    }
    
    func testCachedPreviewOrOriginalPath_onSlideShow_shouldReturnNil() throws {
        XCTAssertNil(repo().cachedPreviewOrOriginalPath(for: nodeEntity()))
    }
}
