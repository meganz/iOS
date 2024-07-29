import Combine
import Foundation
import MEGADomain
import MEGAL10n
import MEGAPresentation
import MEGASwiftUI

final class VideoPlaylistsViewModel: ObservableObject {
    let thumbnailLoader: any ThumbnailLoaderProtocol
    private let videoPlaylistsUseCase: any VideoPlaylistUseCaseProtocol
    private(set) var videoPlaylistContentUseCase: any VideoPlaylistContentsUseCaseProtocol
    private let videoPlaylistModificationUseCase: any VideoPlaylistModificationUseCaseProtocol
    private let syncModel: VideoRevampSyncModel
    private let monitorSortOrderChangedDispatchQueue: DispatchQueue
    
    @Published var videoPlaylists = [VideoPlaylistEntity]()
    @Published var shouldShowAddNewPlaylistAlert = false
    @Published var playlistName = ""
    @Published var shouldShowVideoPlaylistPicker = false
    @Published var shouldOpenVideoPlaylistContent = false
    var newlyAddedVideosToPlaylistSnackBarMessage = ""
    
    @Published var shouldShowRenamePlaylistAlert = false
    @Published var shouldShowDeletePlaylistAlert = false
    
    @Published private(set) var shouldShowPlaceHolderView = false
    @Published private(set) var shouldShowVideosEmptyView = false
    
    var selectedVideoPlaylistEntity: VideoPlaylistEntity?
    @Published var isSheetPresented = false
    
    private(set) var newlyCreatedVideoPlaylist: VideoPlaylistEntity?
    
    private var videoPlaylistNames: [String] {
        videoPlaylists.map(\.name)
    }
    
    private(set) var alertViewModel: TextFieldAlertViewModel
    private(set) var renameVideoPlaylistAlertViewModel: TextFieldAlertViewModel
    
    private var subscriptions = Set<AnyCancellable>()
    private(set) var loadVideoPlaylistsOnSearchTextChangedTask: Task<Void, Never>?
    private(set) var createVideoPlaylistTask: Task<Void, Never>?
    private(set) var monitorSortOrderChangedTask: Task<Void, Never>?
    private(set) var renameVideoPlaylistTask: Task<Void, Never>?
    private let contentProvider: any VideoPlaylistsViewModelContentProviderProtocol
    
    init(
        videoPlaylistsUseCase: some VideoPlaylistUseCaseProtocol,
        videoPlaylistContentUseCase: some VideoPlaylistContentsUseCaseProtocol,
        videoPlaylistModificationUseCase: some VideoPlaylistModificationUseCaseProtocol,
        syncModel: VideoRevampSyncModel,
        alertViewModel: TextFieldAlertViewModel,
        renameVideoPlaylistAlertViewModel: TextFieldAlertViewModel,
        thumbnailLoader: some ThumbnailLoaderProtocol,
        contentProvider: some VideoPlaylistsViewModelContentProviderProtocol,
        monitorSortOrderChangedDispatchQueue: DispatchQueue = DispatchQueue.main
    ) {
        self.videoPlaylistsUseCase = videoPlaylistsUseCase
        self.videoPlaylistContentUseCase = videoPlaylistContentUseCase
        self.videoPlaylistModificationUseCase = videoPlaylistModificationUseCase
        self.syncModel = syncModel
        self.alertViewModel = alertViewModel
        self.renameVideoPlaylistAlertViewModel = renameVideoPlaylistAlertViewModel
        self.monitorSortOrderChangedDispatchQueue = monitorSortOrderChangedDispatchQueue
        self.thumbnailLoader = thumbnailLoader
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
        listenSearchTextChange()
        monitorSortOrderChanged()
        subscribeToItemsStateForEmptyState()
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
        await loadVideoPlaylists()
        await monitorVideoPlaylists()
    }
   
    @MainActor
    private func monitorVideoPlaylists() async {
        for await _ in videoPlaylistsUseCase.videoPlaylistsUpdatedAsyncSequence {
            guard !Task.isCancelled else {
                break
            }
            await loadVideoPlaylists()
        }
    }
    
    @MainActor
    private func loadVideoPlaylists(sortOrder: SortOrderEntity? = nil) async {
        shouldShowPlaceHolderView = videoPlaylists.isEmpty
        
        videoPlaylists = await contentProvider.loadVideoPlaylists(
            sortOrder: sortOrder ?? syncModel.videoRevampVideoPlaylistsSortOrderType)
        
        shouldShowPlaceHolderView = false
    }
    
    private func monitorSortOrderChanged() {
        syncModel.$videoRevampVideoPlaylistsSortOrderType
            .debounce(for: .seconds(0.3), scheduler: monitorSortOrderChangedDispatchQueue)
            .removeDuplicates()
            .dropFirst()
            .sink { [weak self] sortOrderType in
                guard let self else { return }
                self.monitorSortOrderChangedTask = Task { @MainActor in
                    guard !Task.isCancelled else {
                        return
                    }
                    await self.loadVideoPlaylists(sortOrder: sortOrderType)
                }
            }
            .store(in: &subscriptions)
    }
    
    private func listenSearchTextChange() {
        syncModel
            .$searchText
            .debounce(for: .seconds(0.3), scheduler: DispatchQueue.main)
            .sink { [weak self] value in
                guard let self else { return }
                if value.isEmpty {
                    loadVideoPlaylistsOnSearchTextChangedTask = Task { @MainActor [weak self] in
                        guard !Task.isCancelled, let self else {
                            return
                        }
                        await loadVideoPlaylists()
                    }
                } else {
                    videoPlaylists = videoPlaylists.filter { $0.name.localizedCaseInsensitiveContains(value) }
                }
            }
            .store(in: &subscriptions)
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
        isSheetPresented = true
    }
    
    func didSelectActionSheetMenuAction(_ contextAction: ContextAction) {
        switch contextAction.type {
        case .rename:
            shouldShowRenamePlaylistAlert = true
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
            id: oldVideoPlaylist.id,
            name: newName,
            coverNode: oldVideoPlaylist.coverNode,
            count: oldVideoPlaylist.count,
            type: oldVideoPlaylist.type,
            creationTime: oldVideoPlaylist.creationTime,
            modificationTime: oldVideoPlaylist.modificationTime,
            sharedLinkStatus: oldVideoPlaylist.sharedLinkStatus
        )
    }
    
    func deleteVideoPlaylist(_ videoPlaylist: VideoPlaylistEntity) async {
        let deletedVideoPlaylists = await videoPlaylistModificationUseCase.delete(videoPlaylists: [ videoPlaylist ])
        guard deletedVideoPlaylists.isNotEmpty else {
            return
        }
        let message = Strings.Localizable.Videos.Tab.Playlist.Content.Snackbar.playlistNameDeleted
        syncModel.snackBarMessage = message.replacingOccurrences(of: "[A]", with: videoPlaylist.name)
        syncModel.shouldShowSnackBar = true
    }
    
    private func subscribeToItemsStateForEmptyState() {
        let isEmptyStream = $videoPlaylists.map(\.isEmpty).dropFirst()
        let isLoadingStream = $shouldShowPlaceHolderView.dropFirst()
        
        Publishers.CombineLatest(isEmptyStream, isLoadingStream)
            .map { $0 && !$1 }
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .assign(to: &$shouldShowVideosEmptyView)
    }
}
