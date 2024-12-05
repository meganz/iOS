import ContentLibraries
import MEGADomain
import MEGADomainMock
@testable import MEGAPhotos
import MEGAPresentation
import MEGAPresentationMock
import MEGASwift
import SwiftUI
import Testing

@Suite("AddToAlbumsViewModel Tests")
struct AddToAlbumsViewModelTests {

    @Suite("Ensure Columns Counts")
    @MainActor
    struct ColumnsCount {
        @Test("",
              arguments: [
                (UserInterfaceSizeClass?.some(.compact), 3),
                (UserInterfaceSizeClass?.some(.regular), 5),
                (UserInterfaceSizeClass?.none, 3)]
        )
        func columnCount(
            horizontalSizeClass: UserInterfaceSizeClass?,
            expectedCount: Int
        ) {
            let sut = AddToAlbumsViewModelTests.makeSUT()
            
            #expect(sut.columns(horizontalSizeClass: horizontalSizeClass).count == expectedCount)
        }
    }
   
    @Suite("Monitor User Albums")
    @MainActor
    struct MonitorUseAlbums {
        @Test("Loading album cell view models")
        func userAlbumLoaded() async throws {
            let userAlbum1 = AlbumEntity(id: 4, type: .user, creationTime: try "2024-04-04T22:01:04Z".date)
            let userAlbum2 = AlbumEntity(id: 5, type: .user, creationTime: try "2024-04-05T10:02:04Z".date)
            let userAlbums = [userAlbum1, userAlbum2]
            let monitorUserAlbumsAsyncSequence = SingleItemAsyncSequence(item: userAlbums)
                .eraseToAnyAsyncSequence()
            
            let monitorAlbumsUseCase = MockMonitorAlbumsUseCase(
                monitorUserAlbumsSequence: monitorUserAlbumsAsyncSequence
            )
            let sut = AddToAlbumsViewModelTests.makeSUT(
                monitorAlbumsUseCase: monitorAlbumsUseCase)
            
            await confirmation() { albumViewModelsLoaded in
                let subscription = sut.$albums
                    .dropFirst()
                    .sink {
                        #expect($0 == [AlbumCellViewModel(album: userAlbum2),
                                       AlbumCellViewModel(album: userAlbum1)])
                        albumViewModelsLoaded()
                    }
                
                await sut.monitorUserAlbums()
                subscription.cancel()
            }
        }
    }

    @MainActor
    private static func makeSUT(
        monitorAlbumsUseCase: some MonitorAlbumsUseCaseProtocol = MockMonitorAlbumsUseCase(),
        thumbnailLoader: some ThumbnailLoaderProtocol = MockThumbnailLoader(),
        monitorUserAlbumPhotosUseCase: some MonitorUserAlbumPhotosUseCaseProtocol = MockMonitorUserAlbumPhotosUseCase(),
        nodeUseCase: some NodeUseCaseProtocol = MockNodeUseCase(),
        sensitiveNodeUseCase: some SensitiveNodeUseCaseProtocol = MockSensitiveNodeUseCase(),
        sensitiveDisplayPreferenceUseCase: some SensitiveDisplayPreferenceUseCaseProtocol = MockSensitiveDisplayPreferenceUseCase(),
        albumCoverUseCase: some AlbumCoverUseCaseProtocol = MockAlbumCoverUseCase(),
        contentLibrariesConfiguration: ContentLibraries.Configuration = .init(
            sensitiveNodeUseCase: MockSensitiveNodeUseCase(),
            nodeUseCase: MockNodeUseCase(),
            isAlbumPerformanceImprovementsEnabled: { true })
    ) -> AddToAlbumsViewModel {
        .init(
            monitorAlbumsUseCase: monitorAlbumsUseCase,
            thumbnailLoader: thumbnailLoader,
            monitorUserAlbumPhotosUseCase: monitorUserAlbumPhotosUseCase,
            nodeUseCase: nodeUseCase,
            sensitiveNodeUseCase: sensitiveNodeUseCase,
            sensitiveDisplayPreferenceUseCase: sensitiveDisplayPreferenceUseCase,
            albumCoverUseCase: albumCoverUseCase,
            contentLibrariesConfiguration: contentLibrariesConfiguration)
    }
}
