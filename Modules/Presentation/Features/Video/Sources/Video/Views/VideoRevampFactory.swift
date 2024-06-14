import Combine
import MEGADomain
import MEGAL10n
import MEGASwiftUI
import SwiftUI

public final class VideoRevampSyncModel: ObservableObject {
    @Published public var videoRevampSortOrderType: SortOrderEntity?
    @Published public var videoRevampVideoPlaylistsSortOrderType: SortOrderEntity = .modificationAsc
    @Published public var editMode: EditMode = .inactive {
        didSet {
            showsTabView = editMode.isEditing ? false : true
        }
    }
    @Published public var isAllSelected = false
    @Published public var searchText = ""
    @Published public private(set) var showsTabView = false
    @Published public var currentTab: VideosTab = .all
    @Published public var shouldShowAddNewPlaylistAlert = false
    @Published public var isSearchActive = false
    
    private var subscriptions = Set<AnyCancellable>()
    
    public init() {
        $editMode.combineLatest($isSearchActive)
            .map { editMode, isSearchActive in !(editMode.isEditing || isSearchActive) }
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .assign(to: &$showsTabView)
    }
}

public class VideoRevampFactory {
    public static func makeTabContainerView(
        fileSearchUseCase: some FilesSearchUseCaseProtocol,
        thumbnailUseCase: some ThumbnailUseCaseProtocol,
        syncModel: VideoRevampSyncModel,
        videoSelection: VideoSelection,
        videoPlaylistUseCase: some VideoPlaylistUseCaseProtocol,
        videoPlaylistContentUseCase: some VideoPlaylistContentsUseCaseProtocol,
        videoPlaylistModificationUseCase: some VideoPlaylistModificationUseCaseProtocol,
        videoConfig: VideoConfig,
        router: some VideoRevampRouting
    ) -> UIViewController {
        let videoListViewModel = VideoListViewModel(
            fileSearchUseCase: fileSearchUseCase,
            thumbnailUseCase: thumbnailUseCase,
            syncModel: syncModel,
            selection: videoSelection
        )
        let videoPlaylistViewModel = VideoPlaylistsViewModel(
            videoPlaylistsUseCase: videoPlaylistUseCase,
            thumbnailUseCase: thumbnailUseCase, 
            videoPlaylistContentUseCase: videoPlaylistContentUseCase,
            videoPlaylistModificationUseCase: videoPlaylistModificationUseCase,
            syncModel: syncModel,
            alertViewModel: TextFieldAlertViewModel(
                title: Strings.Localizable.Videos.Tab.Playlist.Content.Alert.title,
                placeholderText: Strings.Localizable.Videos.Tab.Playlist.Content.Alert.placeholder,
                affirmativeButtonTitle: Strings.Localizable.Videos.Tab.Playlist.Content.Alert.Button.create,
                destructiveButtonTitle: Strings.Localizable.cancel,
                message: nil
            )
        )
        let view = TabContainerView(
            videoListViewModel: videoListViewModel,
            videoPlaylistViewModel: videoPlaylistViewModel,
            syncModel: syncModel,
            videoConfig: videoConfig,
            router: router,
            didChangeCurrentTab: { syncModel.currentTab = $0 }
        )
        return UIHostingController(rootView: view)
    }
    
    public static func makeVideoContentContainerView(
        videoConfig: VideoConfig,
        previewEntity: VideoPlaylistEntity,
        videoPlaylistContentUseCase: some VideoPlaylistContentsUseCaseProtocol,
        thumbnailUseCase: some ThumbnailUseCaseProtocol,
        sortOrderPreferenceUseCase: some SortOrderPreferenceUseCaseProtocol,
        router: some VideoRevampRouting,
        sharedUIState: VideoPlaylistContentSharedUIState,
        presentationConfig: VideoPlaylistContentSnackBarPresentationConfig
    ) -> UIViewController {
        let viewModel = VideoPlaylistContentViewModel(
            videoPlaylistEntity: previewEntity,
            videoPlaylistContentsUseCase: videoPlaylistContentUseCase,
            thumbnailUseCase: thumbnailUseCase,
            videoPlaylistThumbnailLoader: VideoPlaylistThumbnailLoader(thumbnailUseCase: thumbnailUseCase),
            sharedUIState: sharedUIState,
            presentationConfig: presentationConfig,
            sortOrderPreferenceUseCase: sortOrderPreferenceUseCase
        )
        let view = PlaylistContentScreen(
            viewModel: viewModel,
            videoConfig: videoConfig,
            router: router
        )
        return UIHostingController(rootView: view)
    }
}
