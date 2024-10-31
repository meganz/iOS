@testable import ContentLibraries
import MEGADomainMock
@testable import MEGAPresentation
import MEGAPresentationMock
import XCTest

final class ThumbnailLoaderFactoryTests: XCTestCase {

    func testMakeThumbnailLoader_featureFlagOffNilMode_shouldReturnThumbnailLoaderInstance() {
        let thumbnailLoader = ThumbnailLoaderFactory.makeThumbnailLoader(
            remoteFeatureFlagUseCase: MockRemoteFeatureFlagUseCase(list: [.hiddenNodes: false]),
            configuration: .mockConfiguration())
        
        XCTAssertTrue(thumbnailLoader is ThumbnailLoader)
    }
    
    func testMakeThumbnailLoader_featureFlagOffModeProvided_shouldReturnThumbnailLoaderInstance() {
        let thumbnailLoader = ThumbnailLoaderFactory.makeThumbnailLoader(
            remoteFeatureFlagUseCase: MockRemoteFeatureFlagUseCase(list: [.hiddenNodes: false]),
            mode: .albumLink,
            configuration: .mockConfiguration())
        
        XCTAssertTrue(thumbnailLoader is ThumbnailLoader)
    }
    
    func testMakeThumbnailLoader_featureFlagOnNilMode_shouldReturnThumbnailLoader() {
        let thumbnailLoader = ThumbnailLoaderFactory.makeThumbnailLoader(
            remoteFeatureFlagUseCase: MockRemoteFeatureFlagUseCase(list: [.hiddenNodes: true]),
            configuration: .mockConfiguration())
        
        XCTAssertTrue(thumbnailLoader is SensitiveThumbnailLoader)
    }
    
    func testMakeThumbnailLoader_featureFlagOnAlbumLinkAndMediaDiscoveryLink_shouldReturnThumbnailLoader() {
        [PhotoLibraryContentMode.albumLink, .mediaDiscoveryFolderLink]
            .forEach {
                let thumbnailLoader = ThumbnailLoaderFactory.makeThumbnailLoader(
                    remoteFeatureFlagUseCase: MockRemoteFeatureFlagUseCase(list: [.hiddenNodes: true]),
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
                        remoteFeatureFlagUseCase: MockRemoteFeatureFlagUseCase(list: [.hiddenNodes: true]),
                        mode: $0,
                        configuration: .mockConfiguration())
                
                XCTAssertTrue(thumbnailLoader is SensitiveThumbnailLoader)
            }
    }
}
