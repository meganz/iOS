import Combine
import ContentLibraries
import MEGADomain
import MEGADomainMock
@testable import MEGAPhotos
import MEGAPresentation
import MEGAPresentationMock
import Testing

@Suite("AddToPlaylistViewModel Tests")
struct AddToPlaylistViewModelTests {
    
    @Suite("Load video playlists")
    @MainActor
    struct LoadVideoPlaylist {
        @Test
        func load() async throws {
            let videoPlaylistOne = VideoPlaylistEntity(
                setIdentifier: SetIdentifier(handle: 1),
                modificationTime: try "2025-01-10T08:00:00Z".date)
            let videoPlaylistTwo = VideoPlaylistEntity(
                setIdentifier: SetIdentifier(handle: 2),
                modificationTime: try "2025-01-09T08:00:00Z".date)
            
            let videoPlaylistsUseCase = MockVideoPlaylistUseCase(
                userVideoPlaylistsResult: [videoPlaylistOne, videoPlaylistTwo])
            let sut = AddToPlaylistViewModelTests
                .makeSUT(videoPlaylistsUseCase: videoPlaylistsUseCase)
            
            #expect(sut.isVideoPlayListsLoaded == false)
            
            var cancellable: AnyCancellable?
            await confirmation("Playlist loaded") { playlistLoaded in
                cancellable = sut.$videoPlaylists
                    .dropFirst()
                    .sink {
                        #expect($0 == [videoPlaylistTwo, videoPlaylistOne])
                        playlistLoaded()
                    }
                
                await sut.loadVideoPlaylists()
            }
            #expect(sut.isVideoPlayListsLoaded == true)
            cancellable?.cancel()
        }
    }
    
    @MainActor
    private static func makeSUT(
        thumbnailLoader: some ThumbnailLoaderProtocol = MockThumbnailLoader(),
        videoPlaylistContentUseCase: some VideoPlaylistContentsUseCaseProtocol = MockVideoPlaylistContentUseCase(),
        sortOrderPreferenceUseCase: some SortOrderPreferenceUseCaseProtocol = MockSortOrderPreferenceUseCase(sortOrderEntity: .none),
        router: some VideoRevampRouting = MockVideoRevampRouter(),
        videoPlaylistsUseCase: any VideoPlaylistUseCaseProtocol = MockVideoPlaylistUseCase()
    ) -> AddToPlaylistViewModel {
        .init(
            thumbnailLoader: thumbnailLoader,
            videoPlaylistContentUseCase: videoPlaylistContentUseCase,
            sortOrderPreferenceUseCase: sortOrderPreferenceUseCase,
            router: router,
            videoPlaylistsUseCase: videoPlaylistsUseCase)
    }
}
