import AsyncAlgorithms
import Combine
import MEGADomain
import MEGAL10n
import MEGASwiftUI

public protocol VideoPlaylistContentViewModelSelectionDelegate: AnyObject {
    
    /// A delegate method to handle all selected button triggered. Implement this to get the event of all selected button alongside the corresponding varaibles.
    /// - Parameters:
    ///   - allSelected: A boolean that indicates all selected state, either all selected active, or inactive.
    ///   - videos: Collection of videos that displayed as the target of all selected state changed.
    func didChangeAllSelectedValue(allSelected: Bool, videos: [NodeEntity])
}

final class VideoPlaylistContentViewModel: ObservableObject {
    
    private(set) var videoPlaylistEntity: VideoPlaylistEntity
    private let videoPlaylistContentsUseCase: any VideoPlaylistContentsUseCaseProtocol
    private(set) var thumbnailUseCase: any ThumbnailUseCaseProtocol
    private let videoPlaylistThumbnailLoader: any VideoPlaylistThumbnailLoaderProtocol
    private let sortOrderPreferenceUseCase: any SortOrderPreferenceUseCaseProtocol
    private weak var selectionDelegate: VideoPlaylistContentViewModelSelectionDelegate?
    private(set) var renameVideoPlaylistAlertViewModel: TextFieldAlertViewModel
    private let videoPlaylistsUseCase: any VideoPlaylistUseCaseProtocol
    private let videoPlaylistModificationUseCase: any VideoPlaylistModificationUseCaseProtocol
    
    @Published public private(set) var videos: [NodeEntity] = []
    @Published var headerPreviewEntity: VideoPlaylistCellPreviewEntity = .placeholder
    @Published var secondaryInformationViewType: VideoPlaylistCellViewModel.SecondaryInformationViewType = .emptyPlaylist
    @Published var shouldPopScreen = false
    @Published var shouldShowError = false
    @Published var shouldShowRenamePlaylistAlert = false
    
    @Published var shouldShowVideoPlaylistPicker = false
    
    public private(set) var sharedUIState: VideoPlaylistContentSharedUIState
    
    private(set) var presentationConfig: VideoPlaylistContentSnackBarPresentationConfig?
    
    private(set) var videoPlaylistNames: [String] = []
    
    private(set) var renameVideoPlaylistTask: Task<Void, Never>?
    
    init(
        videoPlaylistEntity: VideoPlaylistEntity,
        videoPlaylistContentsUseCase: some VideoPlaylistContentsUseCaseProtocol,
        thumbnailUseCase: some ThumbnailUseCaseProtocol,
        videoPlaylistThumbnailLoader: some VideoPlaylistThumbnailLoaderProtocol,
        sharedUIState: VideoPlaylistContentSharedUIState,
        presentationConfig: VideoPlaylistContentSnackBarPresentationConfig? = nil,
        sortOrderPreferenceUseCase: some SortOrderPreferenceUseCaseProtocol,
        selectionDelegate: some VideoPlaylistContentViewModelSelectionDelegate,
        renameVideoPlaylistAlertViewModel: TextFieldAlertViewModel,
        videoPlaylistsUseCase: some VideoPlaylistUseCaseProtocol,
        videoPlaylistModificationUseCase: some VideoPlaylistModificationUseCaseProtocol
    ) {
        self.videoPlaylistEntity = videoPlaylistEntity
        self.videoPlaylistContentsUseCase = videoPlaylistContentsUseCase
        self.thumbnailUseCase = thumbnailUseCase
        self.videoPlaylistThumbnailLoader = videoPlaylistThumbnailLoader
        self.sortOrderPreferenceUseCase = sortOrderPreferenceUseCase
        self.sharedUIState = sharedUIState
        self.presentationConfig = presentationConfig
        self.selectionDelegate = selectionDelegate
        self.renameVideoPlaylistAlertViewModel = renameVideoPlaylistAlertViewModel
        self.videoPlaylistsUseCase = videoPlaylistsUseCase
        self.videoPlaylistModificationUseCase = videoPlaylistModificationUseCase
        
        assignVideoPlaylistRenameValidator()
        
        self.renameVideoPlaylistAlertViewModel.action = { [weak self] newVideoPlaylistName in
            self?.renameVideoPlaylist(with: newVideoPlaylistName)
        }
    }
    
    @MainActor
    func onViewAppeared() async {
        configureSnackBar()
        await monitorUserVideoPlaylist()
    }
    
    private func configureSnackBar() {
        sharedUIState.shouldShowSnackBar = presentationConfig?.shouldShowSnackBar ?? false
        sharedUIState.snackBarText = presentationConfig?.text ?? ""
    }
    
    @MainActor
    private func monitorUserVideoPlaylist() async {
        do {
            let sortOrderChangedSequence = sortOrderPreferenceUseCase.monitorSortOrder(for: . videoPlaylistContent)
                .compactMap {  [weak self] (sortOrder: SortOrderEntity) -> SortOrderEntity? in
                    guard let self else {
                        return nil
                    }
                    return doesSupport(sortOrder) ? sortOrder : .defaultAsc
                }
                .removeDuplicates()
                .values
            
            let anyVideoPlaylistUpdateSequence = combineLatest(
                videoPlaylistContentsUseCase.monitorVideoPlaylist(for: videoPlaylistEntity),
                videoPlaylistContentsUseCase.monitorUserVideoPlaylistContent(for: videoPlaylistEntity),
                sortOrderChangedSequence
            )
            
            for try await (videoPlaylist, videos, sortOrder) in anyVideoPlaylistUpdateSequence {
                guard !Task.isCancelled else {
                    break
                }
                self.videoPlaylistEntity = videoPlaylist
                self.videos = VideoPlaylistContentSorter.sort(videos, by: sortOrder)
                self.sharedUIState.videosCount = videos.count
                await loadThumbnails(for: videos)
            }
        } catch {
            handle(error)
        }
    }
    
    @MainActor
    private func loadThumbnails(for videos: [NodeEntity]) async {
        let imageContainers = await videoPlaylistThumbnailLoader.loadThumbnails(for: videos)
        
        headerPreviewEntity = videoPlaylistEntity.toVideoPlaylistCellPreviewEntity(
            thumbnailContainers: imageContainers.compactMap { $0 },
            videosCount: videos.count,
            durationText: durationText(from: videos)
        )
        
        secondaryInformationViewType = videos.count == 0 ? .emptyPlaylist : .information
    }
    
    private func durationText(from videos: [NodeEntity]) -> String {
        let playlistDuration = videos
            .map(\.duration)
            .reduce(0, +)
        
        return VideoDurationFormatter.formatDuration(seconds: UInt(max(playlistDuration, 0)))
    }
    
    // Later when handling delete video playlist, we will handle this in detail wether it should pop screen or show error depending on error case.
    @MainActor
    private func handle(_ error: any Error) {
        guard let videoPlaylistError = error as? VideoPlaylistErrorEntity else {
            shouldShowError = true
            return
        }
        
        switch videoPlaylistError {
        case .videoPlaylistNotFound:
            shouldPopScreen = true
        default:
            shouldShowError = true
        }
    }
    
    private func doesSupport(_ sortOrder: SortOrderEntity) -> Bool {
        [.defaultAsc, .defaultDesc, .modificationAsc, .modificationDesc].contains(sortOrder)
    }
    
    @MainActor
    func addVideosToVideoPlaylist(videos: [NodeEntity]) async {
        guard videos.isNotEmpty else {
            return
        }
        do {
            let resultEntity = try await videoPlaylistModificationUseCase.addVideoToPlaylist(
                by: videoPlaylistEntity.id,
                nodes: videos
            )
            let successfulVideoCount = Int(resultEntity.success)
            if resultEntity.failure == 0 && successfulVideoCount != 0 {
                let newlyAddedVideosToPlaylistSnackBarMessage = addVideosToVideoPlaylistSucessfulMessage(videosCount: successfulVideoCount, videoPlaylistName: videoPlaylistEntity.name)
                sharedUIState.snackBarText = newlyAddedVideosToPlaylistSnackBarMessage
                sharedUIState.shouldShowSnackBar = true
            }
        } catch {
            // Better to log the cancellation in future MR. Currently MEGALogger is from main module.
        }
    }
    
    private func addVideosToVideoPlaylistSucessfulMessage(videosCount: Int, videoPlaylistName: String) -> String {
        Strings.Localizable.Videos.Tab.Playlist.Snackbar.videoCount(videosCount)
            .replacingOccurrences(of: "[A]", with: videoPlaylistName)
    }
    
    @MainActor
    func subscribeToAllSelected() async {
        for await value in sharedUIState.$isAllSelected.values {
            selectionDelegate?.didChangeAllSelectedValue(allSelected: value, videos: videos)
        }
    }
    
    @MainActor
    func subscribeToSelectedDisplayActionChanged() async {
        for await action in sharedUIState.$selectedQuickActionEntity.values {
            switch action {
            case .rename:
                shouldShowRenamePlaylistAlert = true
            default:
                break
            }
        }
    }
    
    private func assignVideoPlaylistRenameValidator() {
        let validator = VideoPlaylistNameValidator(existingVideoPlaylistNames: { [weak self] in
            self?.videoPlaylistNames ?? []
        })
        renameVideoPlaylistAlertViewModel.validator = { validator.validateWhenRenamed(into: $0) }
    }
    
    func monitorVideoPlaylists() async {
        await loadVideoPlaylists()
        
        for await _ in videoPlaylistsUseCase.videoPlaylistsUpdatedAsyncSequence {
            guard !Task.isCancelled else {
                break
            }
            await loadVideoPlaylists()
        }
    }
    
    @MainActor
    private func loadVideoPlaylists(sortOrder: SortOrderEntity? = nil) async {
        let systemVideoPlaylistNames = [Strings.Localizable.Videos.Tab.Playlist.Content.PlaylistCell.Title.favorites]
        let userVideoPlaylistNames = await videoPlaylistsUseCase.userVideoPlaylists().map(\.name)
        videoPlaylistNames = systemVideoPlaylistNames + userVideoPlaylistNames
    }
    
    func renameVideoPlaylist(with newName: String?) {
        if newName == nil || newName == "" || newName?.isEmpty == true {
            return
        }
        
        renameVideoPlaylistTask = Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                guard videoPlaylistEntity.type == .user else {
                    return
                }
                let mappedName = VideoPlaylistNameCreationMapper.videoPlaylistName(from: newName, from: videoPlaylistNames)
                try await videoPlaylistModificationUseCase.updateVideoPlaylistName(mappedName, for: videoPlaylistEntity)
                videoPlaylistEntity.name = mappedName
                headerPreviewEntity.title = videoPlaylistEntity.name
            } catch {
                // Better to log the cancellation in future MR. Currently MEGALogger is from main module.
                sharedUIState.snackBarText = Strings.Localizable.Videos.Tab.Playlist.Content.Snackbar.renamingFailed
                sharedUIState.shouldShowSnackBar = true
            }
        }
    }
}
