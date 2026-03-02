@testable import ContentLibraries
@testable import MEGAAppPresentation
import MEGAAppPresentationMock
import MEGADomainMock
import XCTest

final class ThumbnailLoaderFactoryTests: XCTestCase {
    
    func testMakeThumbnailLoader_featureFlagOnNilMode_shouldReturnThumbnailLoader() {
        let thumbnailLoader = ThumbnailLoaderFactory.makeThumbnailLoader(
            configuration: .mockConfiguration())
        
        XCTAssertTrue(thumbnailLoader is SensitiveThumbnailLoader)
    }
    
    func testMakeThumbnailLoader_featureFlagOnAlbumLinkAndMediaDiscoveryLink_shouldReturnThumbnailLoader() {
        [PhotoLibraryContentMode.albumLink, .mediaDiscoveryFolderLink, .mediaDiscoverySharedItems]
            .forEach {
                let thumbnailLoader = ThumbnailLoaderFactory.makeThumbnailLoader(
                    mode: $0,
                    configuration: .mockConfiguration())
                
                XCTAssertTrue(thumbnailLoader is ThumbnailLoader)
            }
    }
    
    func testMakeThumbnailLoader_featureFlagOnModeProvidedNonLinkModes_shouldReturnSensitiveThumbnailLoader() {
        [PhotoLibraryContentMode.library, .album, .mediaDiscovery]
            .forEach {
                let thumbnailLoader = ThumbnailLoaderFactory
                    .makeThumbnailLoader(
                        mode: $0,
                        configuration: .mockConfiguration())
                
                XCTAssertTrue(thumbnailLoader is SensitiveThumbnailLoader)
            }
    }
}
