import Combine
import Foundation
import MEGADomain
import MEGAL10n
import MEGAPresentation
import MEGASwiftUI

final class VideoPlaylistsViewModel: ObservableObject {
    
    enum ViewState: Equatable {
        case partial
        case loading
        case loaded
        case empty
        case error
    }
    
    enum MonitorSearchRequest {
        /// Request invalidate results and perform search request immediately
        case invalidate
        /// Reinitialise results and perform search request when a change has occurred since before
        case reinitialise
    }
    
    let thumbnailLoader: any ThumbnailLoaderProtocol
    private let videoPlaylistsUseCase: any VideoPlaylistUseCaseProtocol
    private(set) var videoPlaylistContentUseCase: any VideoPlaylistContentsUseCaseProtocol
    private let videoPlaylistModificationUseCase: any VideoPlaylistModificationUseCaseProtocol
    let sortOrderPreferenceUseCase: any SortOrderPreferenceUseCaseProtocol

    private let syncModel: VideoRevampSyncModel
    private let monitorSortOrderChangedDispatchQueue: DispatchQueue
    private let featureFlagProvider: any FeatureFlagProviderProtocol
    
    @Published var videoPlaylists = [VideoPlaylistEntity]()
    @Published var shouldShowAddNewPlaylistAlert = false
    @Published var playlistName = ""
    @Published var shouldShowVideoPlaylistPicker = false
    @Published var shouldOpenVideoPlaylistContent = false
    var newlyAddedVideosToPlaylistSnackBarMessage = ""
    
    @Published var shouldShowRenamePlaylistAlert = false
    @Published var shouldShowDeletePlaylistAlert = false
    @Published private(set) var viewState: ViewState = .partial

    private(set) var selectedVideoPlaylistEntity: VideoPlaylistEntity?
    @Published var isSheetPresented = false
    
    private(set) var newlyCreatedVideoPlaylist: VideoPlaylistEntity?
    
    private var videoPlaylistNames: [String] {
        videoPlaylists.map(\.name)
    }
    
    @Published var shouldShowShareLinkContextActionForSelectedVideoPlaylist = false
    
    private(set) var alertViewModel: TextFieldAlertViewModel
    private(set) var renameVideoPlaylistAlertViewModel: TextFieldAlertViewModel
    
    private var subscriptions = Set<AnyCancellable>()
    private(set) var loadVideoPlaylistsOnSearchTextChangedTask: Task<Void, Never>?
    private(set) var createVideoPlaylistTask: Task<Void, Never>?
    private(set) var renameVideoPlaylistTask: Task<Void, Never>?
    private let contentProvider: any VideoPlaylistsViewModelContentProviderProtocol
    private let monitorSearchRequestsSubject = CurrentValueSubject<MonitorSearchRequest, Never>(.invalidate)

    private var monitorVideoPlaylistsUpdatesTask: Task<Void, Never>? {
        didSet { oldValue?.cancel() }
    }
    init(
        videoPlaylistsUseCase: some VideoPlaylistUseCaseProtocol,
        videoPlaylistContentUseCase: some VideoPlaylistContentsUseCaseProtocol,
        videoPlaylistModificationUseCase: some VideoPlaylistModificationUseCaseProtocol,
        sortOrderPreferenceUseCase: some SortOrderPreferenceUseCaseProtocol,
        syncModel: VideoRevampSyncModel,
        alertViewModel: TextFieldAlertViewModel,
        renameVideoPlaylistAlertViewModel: TextFieldAlertViewModel,
        thumbnailLoader: some ThumbnailLoaderProtocol,
        featureFlagProvider: some FeatureFlagProviderProtocol,
        contentProvider: some VideoPlaylistsViewModelContentProviderProtocol,
        monitorSortOrderChangedDispatchQueue: DispatchQueue = DispatchQueue.main
    ) {
        self.videoPlaylistsUseCase = videoPlaylistsUseCase
        self.videoPlaylistContentUseCase = videoPlaylistContentUseCase
        self.videoPlaylistModificationUseCase = videoPlaylistModificationUseCase
        self.sortOrderPreferenceUseCase = sortOrderPreferenceUseCase
        self.syncModel = syncModel
        self.alertViewModel = alertViewModel
        self.renameVideoPlaylistAlertViewModel = renameVideoPlaylistAlertViewModel
        self.monitorSortOrderChangedDispatchQueue = monitorSortOrderChangedDispatchQueue
        self.thumbnailLoader = thumbnailLoader
        self.featureFlagProvider = featureFlagProvider
        self.contentProvider = contentProvider
        
        syncModel.$shouldShowAddNewPlaylistAlert.assign(to: &$shouldShowAddNewPlaylistAlert)
        
        self.alertViewModel.action = { [weak self] newVideoPlaylistName in
            self?.createUserVideoPlaylist(with: newVideoPlaylistName)
        }
        
        self.renameVideoPlaylistAlertViewModel.action = { [weak self] newVideoPlaylistName in
            self?.renameVideoPlaylist(with: newVideoPlaylistName)
        }
        
        assignVideoPlaylistNameValidator()
        assignVideoPlaylistRenameValidator()
        
        monitorVideoPlaylistsUpdatesTask = Task { @MainActor in await monitorVideoPlaylistsUpdates() }
    }
    
    private func assignVideoPlaylistNameValidator() {
        let validator = VideoPlaylistNameValidator(existingVideoPlaylistNames: { [weak self] in
            self?.videoPlaylistNames ?? []
        })
        alertViewModel.validator = { try? validator.validateWhenCreated(with: $0) }
    }
    
    private func assignVideoPlaylistRenameValidator() {
        let validator = VideoPlaylistNameValidator(existingVideoPlaylistNames: { [weak self] in
            self?.videoPlaylistNames ?? []
        })
        renameVideoPlaylistAlertViewModel.validator = { validator.validateWhenRenamed(into: $0) }
    }
    
    @MainActor
    func onViewAppeared() async {
        await monitorSearchChanges()
    }
   
    @MainActor
    private func monitorVideoPlaylistsUpdates() async {
        for await _ in videoPlaylistsUseCase.videoPlaylistsUpdatedAsyncSequence {
            guard !Task.isCancelled else {
                break
            }
            await contentProvider.invalidateContent()
            monitorSearchRequestsSubject.send(.invalidate)
        }
    }
        
    @MainActor
    private func monitorSearchChanges() async {
        
        let sortOrder = syncModel.$videoRevampVideoPlaylistsSortOrderType
            .removeDuplicates()

        let scheduler = DispatchQueue(label: "VideoPlaylistsSearchMonitor", qos: .userInteractive)
        let searchText = syncModel.$searchText
            .removeDuplicates()
            .debounceImmediate(for: .milliseconds(500), scheduler: scheduler)
        
        let queryParamSequence = searchText.combineLatest(sortOrder)
        
        let asyncSequence = monitorSearchRequestsSubject
            .map { monitorSearchRequest in
                switch monitorSearchRequest {
                case .invalidate:
                    queryParamSequence
                        .eraseToAnyPublisher()
                case .reinitialise:
                    queryParamSequence
                        .dropFirst()
                        .eraseToAnyPublisher()
                }
            }
            .switchToLatest()
            .values
        
        for await (searchText, sortOrder) in asyncSequence {
            performSearch(searchText: searchText, sortOrderType: sortOrder)
        }
    }
    
    private func performSearch(searchText: String, sortOrderType: SortOrderEntity) {
        
        if viewState == .partial {
            viewState = .loading
        }
        
        loadVideoPlaylistsOnSearchTextChangedTask = Task { @MainActor in
            do {
                try await loadVideoPlaylists(searchText: searchText, sortOrder: sortOrderType)
                try Task.checkCancellation()
                viewState = videoPlaylists.isNotEmpty ? .loaded : .empty
            } catch is CancellationError {
                // Better to log the cancellation in future MR. Currently MEGALogger is from main module.
            } catch {
                viewState = videoPlaylists.isEmpty ? .error : .loaded
            }
        }
    }
    
    @MainActor
    private func loadVideoPlaylists(searchText: String, sortOrder: SortOrderEntity) async throws {
        videoPlaylists = try await contentProvider.loadVideoPlaylists(searchText: searchText, sortOrder: sortOrder)
    }
    
    func createUserVideoPlaylist(with name: String?) {
        guard let name else { return }
        createVideoPlaylistTask = Task {
            do {
                let mappedName = VideoPlaylistNameCreationMapper.videoPlaylistName(from: name, from: videoPlaylistNames)
                newlyCreatedVideoPlaylist = try await videoPlaylistsUseCase.createVideoPlaylist(mappedName)
                shouldShowVideoPlaylistPicker = true
            } catch {
                // Better to log the cancellation in future MR. Currently MEGALogger is from main module.
            }
        }
    }
    
    func onViewDisappear() {
        cancelCreateVideoPlaylistTask()
        cancelRenameVideoPlaylistTask()
        newlyCreatedVideoPlaylist = nil
        monitorSearchRequestsSubject.send(.reinitialise)
    }
    
    private func cancelCreateVideoPlaylistTask() {
        createVideoPlaylistTask?.cancel()
        createVideoPlaylistTask = nil
    }
    
    private func cancelRenameVideoPlaylistTask() {
        renameVideoPlaylistTask?.cancel()
        renameVideoPlaylistTask = nil
    }
    
    @MainActor
    func addVideosToNewlyCreatedVideoPlaylist(videos: [NodeEntity]) async {
        do {
            guard let newlyCreatedVideoPlaylist else {
                return
            }
            let resultEntity = try await videoPlaylistModificationUseCase.addVideoToPlaylist(
                by: newlyCreatedVideoPlaylist.id,
                nodes: videos
            )
            let successfullVideoCount = Int(resultEntity.success)
            if resultEntity.failure == 0 && successfullVideoCount != 0 {
                newlyAddedVideosToPlaylistSnackBarMessage = addVideosToVideoPlaylistSucessfulMessage(videosCount: successfullVideoCount, videoPlaylistName: newlyCreatedVideoPlaylist.name)
                shouldOpenVideoPlaylistContent = true
            }
        } catch {
            // Better to log the cancellation in future MR. Currently MEGALogger is from main module.
        }
    }
    
    private func addVideosToVideoPlaylistSucessfulMessage(videosCount: Int, videoPlaylistName: String) -> String {
        let message = Strings.Localizable.Videos.Tab.Playlist.Snackbar.videoCount(videosCount)
        return message.replacingOccurrences(of: "[A]", with: videoPlaylistName)
    }
    
    func didSelectMoreOptionForItem(_ selectedVideoPlaylistEntity: VideoPlaylistEntity) {
        guard selectedVideoPlaylistEntity.type == .user else {
            return
        }
        self.selectedVideoPlaylistEntity = selectedVideoPlaylistEntity
        
        shouldShowShareLinkContextActionForSelectedVideoPlaylist = featureFlagProvider.isFeatureFlagEnabled(for: .videoPlaylistSharing)
        && !selectedVideoPlaylistEntity.isLinkShared
        
        isSheetPresented = true
    }
    
    func didSelectActionSheetMenuAction(_ contextAction: ContextAction) {
        switch contextAction.type {
        case .rename:
            shouldShowRenamePlaylistAlert = true
        case .shareLink:
            break
        case .deletePlaylist:
            shouldShowDeletePlaylistAlert = true
        }
    }
    
    func renameVideoPlaylist(with newName: String?) {
        guard newName != nil || (newName?.isNotEmpty == true) else {
            return
        }
        
        renameVideoPlaylistTask = Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                guard let selectedVideoPlaylistEntity, selectedVideoPlaylistEntity.type == .user else {
                    return
                }
                let mappedName = VideoPlaylistNameCreationMapper.videoPlaylistName(from: newName, from: videoPlaylistNames)
                try await videoPlaylistsUseCase.updateVideoPlaylistName(mappedName, for: selectedVideoPlaylistEntity)
                
                guard let foundIndex = videoPlaylists.firstIndex(where: { $0.id == selectedVideoPlaylistEntity.id }) else {
                    return
                }
                videoPlaylists[foundIndex] = newlyRenamedVideoPlaylist(newName: mappedName, oldVideoPlaylist: selectedVideoPlaylistEntity)
            } catch {
                // Better to log the cancellation in future MR. Currently MEGALogger is from main module.
                syncModel.snackBarMessage = Strings.Localizable.Videos.Tab.Playlist.Content.Snackbar.renamingFailed
                syncModel.shouldShowSnackBar = true
            }
            
            selectedVideoPlaylistEntity = nil
        }
    }
    
    private func newlyRenamedVideoPlaylist(newName: String, oldVideoPlaylist: VideoPlaylistEntity) -> VideoPlaylistEntity {
        VideoPlaylistEntity(
            setIdentifier: oldVideoPlaylist.setIdentifier,
            name: newName,
            coverNode: oldVideoPlaylist.coverNode,
            count: oldVideoPlaylist.count,
            type: oldVideoPlaylist.type,
            creationTime: oldVideoPlaylist.creationTime,
            modificationTime: oldVideoPlaylist.modificationTime,
            sharedLinkStatus: oldVideoPlaylist.sharedLinkStatus
        )
    }
    
    @MainActor
    func deleteSelectedVideoPlaylist() async {
        
        guard let selectedVideoPlaylistEntity else {
            return
        }
        
        let deletedVideoPlaylists = await videoPlaylistModificationUseCase
            .delete(videoPlaylists: [selectedVideoPlaylistEntity])
        
        guard deletedVideoPlaylists.isNotEmpty else {
            return
        }
        
        let message = Strings.Localizable.Videos.Tab.Playlist.Content.Snackbar.playlistNameDeleted
        syncModel.snackBarMessage = message
            .replacingOccurrences(of: "[A]", with: selectedVideoPlaylistEntity.name)
        syncModel.shouldShowSnackBar = true
    }
}
