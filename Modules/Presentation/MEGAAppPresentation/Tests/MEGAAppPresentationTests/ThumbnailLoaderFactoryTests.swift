@testable import MEGAAppPresentation
import MEGAAppPresentationMock
import MEGADomainMock
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
                                 thumbnailUseCase: MockThumbnailUseCase())
        
        XCTAssertTrue(thumbnailLoader is SensitiveThumbnailLoader)
    }
    
    // MARK: MakeThumbnailLoder with fallback
    
    func testMakeThumbnailLoaderWithFallback_configIsGeneral_shouldReturnThumbnailLoaderInstance() {
        let thumbnailLoader = ThumbnailLoaderFactory
            .makeThumbnailLoader(
                config: .generalWithFallBackIcon(nodeIconUseCase: MockNodeIconUsecase(stubbedIconData: anyData())),
                thumbnailUseCase: MockThumbnailUseCase()
            )
        
        XCTAssertTrue(thumbnailLoader is ThumbnailLoaderWithFallbackIcon)
    }
    
    func testMakeThumbnailLoaderWithFallback_configIsSensitiveIfFeatureFlagOn_shouldReturnSensitiveThumbnailLoader() {
        
        let thumbnailLoader = ThumbnailLoaderFactory
            .makeThumbnailLoader(
                config: .sensitiveWithFallbackIcon(
                    sensitiveNodeUseCase: MockSensitiveNodeUseCase(),
                    nodeIconUseCase: MockNodeIconUsecase(stubbedIconData: anyData())
                ),
                thumbnailUseCase: MockThumbnailUseCase()
            )
        
        XCTAssertTrue(thumbnailLoader is SensitiveThumbnailLoader)
    }
    
    private func anyData() -> Data {
        "any-data".data(using: .utf8)!
    }
}
