import Combine
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
    public let setSelection: SetSelection
    private let videoPlaylistsUseCase: any VideoPlaylistUseCaseProtocol
    private let videoPlaylistModificationUseCase: any VideoPlaylistModificationUseCaseProtocol
    private let addToCollectionRouter: any AddToCollectionRouting
    
    @Published var isVideoPlayListsLoaded = false
    @Published var showCreatePlaylistAlert = false
    @Published public var videoPlaylists = [VideoPlaylistEntity]()
    
    public init(
        thumbnailLoader: some ThumbnailLoaderProtocol,
        videoPlaylistContentUseCase: some VideoPlaylistContentsUseCaseProtocol,
        sortOrderPreferenceUseCase: some SortOrderPreferenceUseCaseProtocol,
        router: some VideoRevampRouting,
        setSelection: SetSelection = SetSelection(
            mode: .single, editMode: .active),
        videoPlaylistsUseCase: some VideoPlaylistUseCaseProtocol,
        videoPlaylistModificationUseCase: some VideoPlaylistModificationUseCaseProtocol,
        addToCollectionRouter: some AddToCollectionRouting
    ) {
        self.thumbnailLoader = thumbnailLoader
        self.videoPlaylistContentUseCase = videoPlaylistContentUseCase
        self.sortOrderPreferenceUseCase = sortOrderPreferenceUseCase
        self.router = router
        self.setSelection = setSelection
        self.videoPlaylistsUseCase = videoPlaylistsUseCase
        self.videoPlaylistModificationUseCase = videoPlaylistModificationUseCase
        self.addToCollectionRouter = addToCollectionRouter
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

extension AddToPlaylistViewModel: AddItemsToCollectionViewModelProtocol {
    var isAddButtonDisabled: AnyPublisher<Bool, Never> {
        setSelection.$selectedSets
            .map { $0.isEmpty }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
    
    var isItemsNotEmptyPublisher: AnyPublisher<Bool, Never> {
        $videoPlaylists
            .map(\.isNotEmpty)
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
    
    func addItems(_ photos: [NodeEntity]) {
        guard let playlist = setSelection.selectedSets.first,
              let playlistName = videoPlaylists.first(where: { $0.setIdentifier == playlist })?.name,
              photos.isNotEmpty else { return }
        
        Task { [videoPlaylistModificationUseCase, addToCollectionRouter] in
            let result = try await videoPlaylistModificationUseCase.addVideoToPlaylist(by: playlist.handle, nodes: photos)
            
            let message = Strings.Localizable.Set.AddTo.Snackbar.message(Int(result.success))
                .replacingOccurrences(of: "[A]", with: playlistName)
            addToCollectionRouter.showSnackBarOnDismiss(message: message)
        }
    }
}
