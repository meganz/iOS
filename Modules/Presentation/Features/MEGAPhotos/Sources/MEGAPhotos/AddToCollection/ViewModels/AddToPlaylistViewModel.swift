import ContentLibraries
import MEGADomain
import MEGAL10n
import MEGAPresentation
import MEGASwiftUI
import SwiftUI

@MainActor
public final class AddToPlaylistViewModel: VideoPlaylistsContentViewModelProtocol {
    public let thumbnailLoader: any ThumbnailLoaderProtocol
    public let videoPlaylistContentUseCase: any VideoPlaylistContentsUseCaseProtocol
    public let sortOrderPreferenceUseCase: any SortOrderPreferenceUseCaseProtocol
    public let router: any VideoRevampRouting
    private let videoPlaylistsUseCase: any VideoPlaylistUseCaseProtocol
    public let setSelection = SetSelection(
        mode: .single, editMode: .active)
    
    @Published var isVideoPlayListsLoaded = false
    @Published var showCreatePlaylistAlert = false
    @Published public var videoPlaylists = [VideoPlaylistEntity]()
    
    public init(
        thumbnailLoader: some ThumbnailLoaderProtocol,
        videoPlaylistContentUseCase: some VideoPlaylistContentsUseCaseProtocol,
        sortOrderPreferenceUseCase: some SortOrderPreferenceUseCaseProtocol,
        router: some VideoRevampRouting,
        videoPlaylistsUseCase: any VideoPlaylistUseCaseProtocol
    ) {
        self.thumbnailLoader = thumbnailLoader
        self.videoPlaylistContentUseCase = videoPlaylistContentUseCase
        self.sortOrderPreferenceUseCase = sortOrderPreferenceUseCase
        self.router = router
        self.videoPlaylistsUseCase = videoPlaylistsUseCase
    }
    
    func loadVideoPlaylists() async {
        videoPlaylists =  await videoPlaylistsUseCase.userVideoPlaylists()
            .sorted { $0.modificationTime > $1.modificationTime }
        
        guard !isVideoPlayListsLoaded else { return }
        isVideoPlayListsLoaded.toggle()
    }
    
    func onCreatePlaylistTapped() {
        showCreatePlaylistAlert.toggle()
    }
    
    func alertViewModel() -> TextFieldAlertViewModel {
        let validator = VideoPlaylistNameValidator(existingVideoPlaylistNames: { [weak self] in
            self?.videoPlaylists.map(\.name) ?? []
        })
        return .init(
            title: Strings.Localizable.Videos.Tab.Playlist.Content.Alert.title,
            placeholderText: Strings.Localizable.Videos.Tab.Playlist.Content.Alert.placeholder,
            affirmativeButtonTitle: Strings.Localizable.Videos.Tab.Playlist.Content.Alert.Button.create,
            destructiveButtonTitle: Strings.Localizable.cancel,
            action: { [weak self] newPlaylist in
                guard let self, let newPlaylist else { return }
                let name = VideoPlaylistNameCreationMapper.videoPlaylistName(
                    from: newPlaylist, from: videoPlaylists.map(\.name))
                Task {
                    _ = try await videoPlaylistsUseCase.createVideoPlaylist(name)
                }
            },
            validator: { try? validator.validateWhenCreated(with: $0) }
        )
    }
    
    func monitorPlaylistUpdates() async {
        for await _ in videoPlaylistsUseCase.videoPlaylistsUpdatedAsyncSequence {
            await loadVideoPlaylists()
        }
    }
}
