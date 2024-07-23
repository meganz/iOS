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
    
    func testMakeThumbnailLoader_configIsSensitiveIfFeatureFlagOn_shouldReturnSensitiveThumbnailLoader() {
        
        let thumbnailLoader = ThumbnailLoaderFactory
            .makeThumbnailLoader(config: .sensitive(sensitiveNodeUseCase: MockSensitiveNodeUseCase()), 
                                 thumbnailUseCase: MockThumbnailUseCase(),
                                 featureFlagProvider: MockFeatureFlagProvider(list: [.hiddenNodes: true]))

        XCTAssertTrue(thumbnailLoader is SensitiveThumbnailLoader)
    }
    
    func testMakeThumbnailLoader_configIsSensitiveIfFeatureFlagOff_shouldReturnGeneralThumbnailLoader() {
        
        let thumbnailLoader = ThumbnailLoaderFactory
            .makeThumbnailLoader(config: .sensitive(sensitiveNodeUseCase: MockSensitiveNodeUseCase()),
                                 thumbnailUseCase: MockThumbnailUseCase(),
                                 featureFlagProvider: MockFeatureFlagProvider(list: [.hiddenNodes: false]))

        XCTAssertTrue(thumbnailLoader is ThumbnailLoader)
    }
}
