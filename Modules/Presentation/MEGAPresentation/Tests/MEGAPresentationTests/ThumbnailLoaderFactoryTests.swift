import MEGADomainMock
@testable import MEGAPresentation
import MEGAPresentationMock
import XCTest

final class ThumbnailLoaderFactoryTests: XCTestCase {

    func testMakeThumbnailLoader_configIsGeneral_shouldReturnThumbnailLoaderInstance() {
        let thumbnailLoader = ThumbnailLoaderFactory
            .makeThumbnailLoader(config: .general, thumbnailUseCase: MockThumbnailUseCase())
        
        XCTAssertTrue(thumbnailLoader is ThumbnailLoader)
    }
    
    func testMakeThumbnailLoader_configIsSensitive_shouldReturnThumbnailLoader() {
        let thumbnailLoader = ThumbnailLoaderFactory
            .makeThumbnailLoader(config: .sensitive(sensitiveNodeUseCase: MockSensitiveNodeUseCase()), 
                                 thumbnailUseCase: MockThumbnailUseCase())

        XCTAssertTrue(thumbnailLoader is SensitiveThumbnailLoader)
    }
}
