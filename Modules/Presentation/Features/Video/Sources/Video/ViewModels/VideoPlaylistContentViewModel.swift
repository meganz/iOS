import AsyncAlgorithms
@preconcurrency import Combine
import ContentLibraries
import Foundation
import MEGADomain
import MEGAL10n
import MEGAPresentation
import MEGASwiftUI

@MainActor
public protocol VideoPlaylistContentViewModelSelectionDelegate: AnyObject {
    
    /// A delegate method to handle all selected button triggered. Implement this to get the event of all selected button alongside the corresponding varaibles.
    /// - Parameters:
    ///   - allSelected: A boolean that indicates all selected state, either all selected active, or inactive.
    ///   - videos: Collection of videos that displayed as the target of all selected state changed.
    func didChangeAllSelectedValue(allSelected: Bool, videos: [NodeEntity])
}

@MainActor
final class VideoPlaylistContentViewModel: ObservableObject {
    
    private(set) var videoPlaylistEntity: VideoPlaylistEntity
    private let videoPlaylistContentsUseCase: any VideoPlaylistContentsUseCaseProtocol
    let thumbnailLoader: any ThumbnailLoaderProtocol
    let sensitiveNodeUseCase: any SensitiveNodeUseCaseProtocol
    let nodeUseCase: any NodeUseCaseProtocol
    let featureFlagProvider: any FeatureFlagProviderProtocol
    private let videoPlaylistThumbnailLoader: any VideoPlaylistThumbnailLoaderProtocol
    private let sortOrderPreferenceUseCase: any SortOrderPreferenceUseCaseProtocol
    private weak var selectionDelegate: VideoPlaylistContentViewModelSelectionDelegate?
    private(set) var renameVideoPlaylistAlertViewModel: TextFieldAlertViewModel
    private let videoPlaylistsUseCase: any VideoPlaylistUseCaseProtocol
    private let videoPlaylistModificationUseCase: any VideoPlaylistModificationUseCaseProtocol
    private let syncModel: VideoRevampSyncModel
    
    @Published public private(set) var videos: [NodeEntity] = []
    @Published var headerPreviewEntity: VideoPlaylistCellPreviewEntity = .placeholder
    @Published var secondaryInformationViewType: VideoPlaylistCellViewModel.SecondaryInformationViewType = .emptyPlaylist
    @Published var shouldPopScreen = false
    @Published var shouldShowRenamePlaylistAlert = false
    @Published var shouldShowDeletePlaylistAlert = false
    @Published var shouldShowDeleteVideosFromVideoPlaylistActionSheet = false
    private(set) var selectedVideos: [NodeEntity]?
    
    @Published var shouldShowVideoPlaylistPicker = false
    @Published var shouldShowShareLinkView = false
    
    @Published private(set) var viewState: ViewState = .partial
    
    enum ViewState: Equatable {
        case partial
        case loading
        case loaded
        case empty
        case error
    }

    var searchText: String {
        syncModel.searchText
    }

    public private(set) var sharedUIState: VideoPlaylistContentSharedUIState
    
    private(set) var presentationConfig: VideoPlaylistContentSnackBarPresentationConfig?
    
    private(set) var videoPlaylistNames: [String] = []
    private(set) var renameVideoPlaylistTask: Task<Void, Never>?
    private(set) var deleteVideoPlaylistTask: Task<Void, Never>?
    private(set) var moveVideoInVideoPlaylistContentToRubbishBinTask: Task<Void, Never>?
    
    private var subscriptions = Set<AnyCancellable>()
    
    init(
        videoPlaylistEntity: VideoPlaylistEntity,
        videoPlaylistContentsUseCase: some VideoPlaylistContentsUseCaseProtocol,
        videoPlaylistThumbnailLoader: some VideoPlaylistThumbnailLoaderProtocol,
        sharedUIState: VideoPlaylistContentSharedUIState,
        presentationConfig: VideoPlaylistContentSnackBarPresentationConfig? = nil,
        sortOrderPreferenceUseCase: some SortOrderPreferenceUseCaseProtocol,
        selectionDelegate: some VideoPlaylistContentViewModelSelectionDelegate,
        renameVideoPlaylistAlertViewModel: TextFieldAlertViewModel,
        videoPlaylistsUseCase: some VideoPlaylistUseCaseProtocol,
        videoPlaylistModificationUseCase: some VideoPlaylistModificationUseCaseProtocol,
        thumbnailLoader: some ThumbnailLoaderProtocol,
        sensitiveNodeUseCase: some SensitiveNodeUseCaseProtocol,
        nodeUseCase: some NodeUseCaseProtocol,
        featureFlagProvider: some FeatureFlagProviderProtocol,
        syncModel: VideoRevampSyncModel
    ) {
        self.videoPlaylistEntity = videoPlaylistEntity
        self.videoPlaylistContentsUseCase = videoPlaylistContentsUseCase
        self.videoPlaylistThumbnailLoader = videoPlaylistThumbnailLoader
        self.sortOrderPreferenceUseCase = sortOrderPreferenceUseCase
        self.sharedUIState = sharedUIState
        self.presentationConfig = presentationConfig
        self.selectionDelegate = selectionDelegate
        self.renameVideoPlaylistAlertViewModel = renameVideoPlaylistAlertViewModel
        self.videoPlaylistsUseCase = videoPlaylistsUseCase
        self.videoPlaylistModificationUseCase = videoPlaylistModificationUseCase
        self.thumbnailLoader = thumbnailLoader
        self.sensitiveNodeUseCase = sensitiveNodeUseCase
        self.nodeUseCase = nodeUseCase
        self.featureFlagProvider = featureFlagProvider
        self.syncModel = syncModel
        
        assignVideoPlaylistRenameValidator()
        
        self.renameVideoPlaylistAlertViewModel.action = { [weak self] newVideoPlaylistName in
            self?.renameVideoPlaylist(with: newVideoPlaylistName)
        }
        
        subscribeToRemoveVideosFromVideoPlaylistAction()
        subscribeToDidSelectMoveVideoInVideoPlaylistContentToRubbishBinAction()
    }
    
    func onViewAppeared() async {
        configureSnackBar()
        await monitorUserVideoPlaylist()
    }
    
    private func configureSnackBar() {
        sharedUIState.shouldShowSnackBar = presentationConfig?.shouldShowSnackBar ?? false
        sharedUIState.snackBarText = presentationConfig?.text ?? ""
    }
    
    func monitorUserVideoPlaylist() async {
        if viewState == .partial {
            viewState = .loading
        }
        
        do {
            let sortOrderChangedSequence = sortOrderPreferenceUseCase.monitorSortOrder(for: . videoPlaylistContent)
                .values
                .compactMap { [weak self] (sortOrder: SortOrderEntity) -> SortOrderEntity? in
                    guard let self else {
                        return nil
                    }
                    return await doesSupport(sortOrder) ? sortOrder : .defaultAsc
                }
                .removeDuplicates()
            
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
                self.videos = await VideoPlaylistContentSorter.sort(videos, by: sortOrder)
                self.sharedUIState.videosCount = videos.count
                await loadThumbnails(for: self.videos)
                viewState = videos.isEmpty ? .empty : .loaded
            }
        } catch {
            handle(error)
        }
    }
    
    private func loadThumbnails(for videos: [NodeEntity]) async {
        let thumbnail = await videoPlaylistThumbnailLoader.loadThumbnails(for: videos)
        
        headerPreviewEntity = videoPlaylistEntity.toVideoPlaylistCellPreviewEntity(
            videoPlaylistThumbnail: thumbnail,
            videosCount: videos.count,
            durationText: await videos.durationText()
        )
        
        secondaryInformationViewType = videos.count == 0 ? .emptyPlaylist : .information
    }
    
    private func handle(_ error: any Error) {
        guard let videoPlaylistError = error as? VideoPlaylistErrorEntity else {
            viewState = .error
            return
        }
        
        switch videoPlaylistError {
        case .videoPlaylistNotFound:
            shouldPopScreen = true
            syncModel.snackBarMessage = Strings.Localizable.Videos.Tab.Playlist.Content.Snackbar.playlistNameDeleted
                .replacingOccurrences(of: "[A]", with: videoPlaylistEntity.name)
            syncModel.shouldShowSnackBar = true
        default:
            viewState = .error
        }
    }
    
    private func doesSupport(_ sortOrder: SortOrderEntity) -> Bool {
        PlaylistContentSupportedSortOrderPolicy.supportedSortOrders.contains(sortOrder)
    }
    
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
    
    func subscribeToAllSelected() async {
        for await value in sharedUIState.$isAllSelected.values {
            selectionDelegate?.didChangeAllSelectedValue(allSelected: value, videos: videos)
        }
    }
    
    func subscribeToSelectedDisplayActionChanged() async {
        for await action in sharedUIState.$selectedQuickActionEntity.values {
            switch action {
            case .rename:
                shouldShowRenamePlaylistAlert = true
            case .shareLink:
                shouldShowShareLinkView = true
            default:
                break
            }
        }
    }
    
    func subscribeToSelectedVideoPlaylistActionChanged() async {
        for await action in sharedUIState.$selectedVideoPlaylistActionEntity.values {
            switch action {
            case .delete:
                shouldShowDeletePlaylistAlert = true
            case .addVideosToVideoPlaylistContent:
                shouldShowVideoPlaylistPicker = true
            default:
                break
            }
        }
    }
    
    func monitorVideoPlaylists() async {
        
        for await _ in videoPlaylistsUseCase.videoPlaylistsUpdatedAsyncSequence.prepend(()) {
            guard !Task.isCancelled else {
                break
            }
            await loadVideoPlaylistsNames()
        }
    }
    
    private func assignVideoPlaylistRenameValidator() {
        let validator = VideoPlaylistNameValidator(existingVideoPlaylistNames: { [weak self] in
            self?.videoPlaylistNames ?? []
        })
        renameVideoPlaylistAlertViewModel.validator = { validator.validateWhenRenamed(into: $0) }
    }
        
    private func loadVideoPlaylistsNames() async {
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

    func deleteVideoPlaylist() {
        guard videoPlaylistEntity.type == .user else {
            return
        }
        
        deleteVideoPlaylistTask = Task { [weak self] in
            guard let self else { return }
            _ = await videoPlaylistModificationUseCase.delete(videoPlaylists: [videoPlaylistEntity])
        }
    }
    
    private func subscribeToRemoveVideosFromVideoPlaylistAction() {
        sharedUIState.didSelectRemoveVideoFromPlaylistAction
            .receive(on: DispatchQueue.main)
            .filter(\.isNotEmpty)
            .sink { [weak self] selectedVideos in
                self?.selectedVideos = selectedVideos
                self?.shouldShowDeleteVideosFromVideoPlaylistActionSheet = true
            }
            .store(in: &subscriptions)
    }
    
    private func subscribeToDidSelectMoveVideoInVideoPlaylistContentToRubbishBinAction() {
        sharedUIState.didSelectMoveVideoInVideoPlaylistContentToRubbishBinAction
            .filter(\.isNotEmpty)
            .sink { [weak self] selectedVideos in
                guard let self else { return }
                moveVideosToRubbishBin(selectedVideos)
            }
            .store(in: &subscriptions)
    }
    
    private func moveVideosToRubbishBin(_ selectedVideos: [NodeEntity]) {
        self.selectedVideos = selectedVideos
        moveVideoInVideoPlaylistContentToRubbishBinTask = Task { @MainActor in
            do {
                try await deleteVideosFromVideoPlaylist(showSnackBar: false)
                sharedUIState
                    .didFinishDeleteVideoFromVideoPlaylistContentThenAboutToMoveToRubbishBinAction
                    .send(selectedVideos)
            } catch {
                // Better to log the cancellation in future MR. Currently MEGALogger is from main module.
            }
        }
    }
    
    func deleteVideosFromVideoPlaylist(showSnackBar: Bool = true) async throws {
        do {
            guard let selectedVideos else {
                return
            }
            defer { self.selectedVideos = nil }
            
            let videosToDelete = await retrieveSelectedVideoPlaylistVideoEntities(selectedVideos)
            let result = try await videoPlaylistModificationUseCase.deleteVideos(in: videoPlaylistEntity.id, videos: videosToDelete)
            
            if showSnackBar {
                sharedUIState.snackBarText = deleteVideosFromVideoPlaylistSnackBarText(videosCount: Int(result.success))
                sharedUIState.shouldShowSnackBar = true
            }
        } catch {
            // Better to log the cancellation in future MR. Currently MEGALogger is from main module.
            throw error
        }
    }
    
    private func retrieveSelectedVideoPlaylistVideoEntities(_ selectedVideos: [NodeEntity]) async -> [VideoPlaylistVideoEntity] {
        let videoPlaylistVideoEntities = await videoPlaylistContentsUseCase.userVideoPlaylistVideos(by: videoPlaylistEntity.id)
        let selectedVideoIds = selectedVideos.map(\.handle)
        return videoPlaylistVideoEntities.filter { selectedVideoIds.contains($0.video.id) }
    }
    
    private func deleteVideosFromVideoPlaylistSnackBarText(videosCount: Int) -> String {
        Strings.Localizable.Videos.Tab.Playlist.PlaylistContent.Snackbar.removedVideosCountFromPlaylistName(videosCount)
            .replacingOccurrences(of: "[A]", with: videoPlaylistEntity.name)
    }
    
    func didTapCancelOnDeleteVideosFromVideoPlaylistActionSheet() {
        selectedVideos = nil
    }
}
