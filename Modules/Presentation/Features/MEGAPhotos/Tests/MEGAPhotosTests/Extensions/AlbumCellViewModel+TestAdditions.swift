import ContentLibraries
import MEGADomain
import MEGADomainMock
import MEGAPresentation
import MEGAPresentationMock
import SwiftUI

extension AlbumCellViewModel {
    convenience init(
        album: AlbumEntity,
        searchText: String? = nil
    ) {
        self.init(
            thumbnailLoader: MockThumbnailLoader(initialImage: ImageContainer(image: Image(systemName: "square"), type: .thumbnail)),
            monitorUserAlbumPhotosUseCase: MockMonitorUserAlbumPhotosUseCase(),
            nodeUseCase: MockNodeDataUseCase(),
            sensitiveNodeUseCase: MockSensitiveNodeUseCase(),
            sensitiveDisplayPreferenceUseCase: MockSensitiveDisplayPreferenceUseCase(),
            albumCoverUseCase: MockAlbumCoverUseCase(),
            album: album,
            selection: AlbumSelection(),
            tracker: MockTracker(),
            searchText: searchText,
            remoteFeatureFlagUseCase: MockRemoteFeatureFlagUseCase(),
            configuration: .init(
                sensitiveNodeUseCase: MockSensitiveNodeUseCase(),
                nodeUseCase: MockNodeUseCase(),
                isAlbumPerformanceImprovementsEnabled: { false })
        )
    }
}
