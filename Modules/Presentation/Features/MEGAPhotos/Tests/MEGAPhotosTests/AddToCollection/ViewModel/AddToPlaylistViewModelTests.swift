import Combine
import ContentLibraries
import MEGADomain
import MEGADomainMock
import MEGAL10n
@testable import MEGAPhotos
import MEGAPresentation
import MEGAPresentationMock
import MEGASwiftUI
import Testing

@Suite("AddToPlaylistViewModel Tests")
struct AddToPlaylistViewModelTests {
    private enum TestError: Error {
        case timeout
    }
    
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
                userVideoPlaylistsResult: [videoPlaylistTwo, videoPlaylistOne])
            let sut = AddToPlaylistViewModelTests
                .makeSUT(videoPlaylistsUseCase: videoPlaylistsUseCase)
            
            #expect(sut.isVideoPlayListsLoaded == false)
            
            var cancellable: AnyCancellable?
            await confirmation("Playlist loaded") { playlistLoaded in
                cancellable = sut.$videoPlaylists
                    .dropFirst()
                    .sink {
                        #expect($0 ==  [videoPlaylistOne, videoPlaylistTwo])
                        playlistLoaded()
                    }
                
                await sut.loadVideoPlaylists()
            }
            #expect(sut.isVideoPlayListsLoaded == true)
            cancellable?.cancel()
        }
    }
    
    @Suite("Create playlist")
    @MainActor
    struct CreatePlaylist {
        @Test("Create playlist tapped toggle show playlist alert")
        func showPlaylistAlert() {
            let sut = makeSUT()
            
            #expect(sut.showCreatePlaylistAlert == false)
            
            sut.onCreatePlaylistTapped()
            
            #expect(sut.showCreatePlaylistAlert == true)
        }
        
        @Suite("Create alert")
        @MainActor
        struct CreateAlert {
            @Test("Alert view model shows correctly")
            func alertViewModel() {
                let sut = makeSUT()
                
                #expect(sut.alertViewModel() == TextFieldAlertViewModel(
                    title: Strings.Localizable.Videos.Tab.Playlist.Content.Alert.title,
                    placeholderText: Strings.Localizable.Videos.Tab.Playlist.Content.Alert.placeholder,
                    affirmativeButtonTitle: Strings.Localizable.Videos.Tab.Playlist.Content.Alert.Button.create,
                    destructiveButtonTitle: Strings.Localizable.cancel))
            }
            
            @Test("when create alert is shown and action is triggered then it should create playlist", arguments: [
                ("My Playlist", "My Playlist"),
                ("", Strings.Localizable.Videos.Tab.Playlist.Content.Alert.placeholder)])
            func createAlertView(playlistName: String, expectedName: String) async {
                let videoPlaylistsUseCase = MockVideoPlaylistUseCase()
                let sut = makeSUT(videoPlaylistsUseCase: videoPlaylistsUseCase)
                let alertViewModel = sut.alertViewModel()
                
                await confirmation("Ensure create user album created") { createdConfirmation in
                    let invocationTask = Task {
                        for await invocation in videoPlaylistsUseCase.invocationSequence {
                            #expect(invocation == .createVideoPlaylist(name: expectedName))
                            createdConfirmation()
                            break
                        }
                    }
                    alertViewModel.action?(playlistName)
                    
                    Task {
                        try? await Task.sleep(nanoseconds: 500_000_000)
                        invocationTask.cancel()
                    }
                    await invocationTask.value
                }
            }
            
            @Test("When nil action passed then it should not create playlist")
            func nilAction() async {
                let videoPlaylistsUseCase = MockVideoPlaylistUseCase()
                let sut = makeSUT(videoPlaylistsUseCase: videoPlaylistsUseCase)
                let alertViewModel = sut.alertViewModel()
                
                await confirmation("Ensure playlist is not created", expectedCount: 0) { createdConfirmation in
                    let invocationTask = Task {
                        for await _ in videoPlaylistsUseCase.invocationSequence {
                            createdConfirmation()
                        }
                    }
                    alertViewModel.action?(nil)
                    
                    Task {
                        try? await Task.sleep(nanoseconds: 500_000_000)
                        invocationTask.cancel()
                    }
                    await invocationTask.value
                }
            }
        }
        
        @Suite("Playlist updates")
        @MainActor
        struct PlaylistUpdates {
            @Test("On playlist updated load playlists")
            func monitorPlaylists() async throws {
                let (videoPlaylistsUpdatedStream, videoPlaylistsUpdatedContinuation) = AsyncStream.makeStream(of: Void.self)
                let videoPlaylist = VideoPlaylistEntity(
                    setIdentifier: SetIdentifier(handle: 1))
                let videoPlaylistsUseCase = MockVideoPlaylistUseCase(
                    userVideoPlaylistsResult: [videoPlaylist],
                    videoPlaylistsUpdatedAsyncSequence: videoPlaylistsUpdatedStream.eraseToAnyAsyncSequence())
                let sut = makeSUT(videoPlaylistsUseCase: videoPlaylistsUseCase)
                
                await confirmation("Ensure playlist is updated") { updateConfirmation in
                    let invocationTask = Task {
                        for await invocation in videoPlaylistsUseCase.invocationSequence {
                            #expect(invocation == .userVideoPlaylists)
                            #expect(sut.videoPlaylists == [videoPlaylist])
                            updateConfirmation()
                            break
                        }
                    }
                    
                    videoPlaylistsUpdatedContinuation.yield(())
                    videoPlaylistsUpdatedContinuation.finish()
                    
                    await sut.monitorPlaylistUpdates()
                    
                    Task {
                        try? await Task.sleep(nanoseconds: 500_000_000)
                        invocationTask.cancel()
                    }
                    await invocationTask.value
                }
            }
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
