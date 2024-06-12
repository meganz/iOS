import Combine
import Foundation
import MEGADomain
import MEGAL10n
import MEGASwiftUI

final class VideoPlaylistsViewModel: ObservableObject {
    private let videoPlaylistsUseCase: any VideoPlaylistUseCaseProtocol
    private(set) var thumbnailUseCase: any ThumbnailUseCaseProtocol
    private(set) var videoPlaylistContentUseCase: any VideoPlaylistContentsUseCaseProtocol
    private let syncModel: VideoRevampSyncModel
    private let monitorSortOrderChangedDispatchQueue: DispatchQueue
    
    @Published var videoPlaylists = [VideoPlaylistEntity]()
    @Published var shouldShowAddNewPlaylistAlert = false
    @Published var playlistName = ""
    @Published var shouldShowVideoPlaylistPicker = false
    
    var selectedVideoPlaylistEntity: VideoPlaylistEntity?
    @Published var isSheetPresented = false
    
    private(set) var newlyCreatedVideoPlaylist: VideoPlaylistEntity?
    
    private var videoPlaylistNames: [String] {
        videoPlaylists.map(\.name)
    }
    
    private(set) var alertViewModel: TextFieldAlertViewModel
    
    private var subscriptions = Set<AnyCancellable>()
    private(set) var loadVideoPlaylistsOnSearchTextChangedTask: Task<Void, Never>?
    private(set) var createVideoPlaylistTask: Task<Void, Never>?
    private(set) var monitorSortOrderChangedTask: Task<Void, Never>?
    
    init(
        videoPlaylistsUseCase: some VideoPlaylistUseCaseProtocol,
        thumbnailUseCase: some ThumbnailUseCaseProtocol,
        videoPlaylistContentUseCase: some VideoPlaylistContentsUseCaseProtocol,
        syncModel: VideoRevampSyncModel,
        alertViewModel: TextFieldAlertViewModel,
        monitorSortOrderChangedDispatchQueue: DispatchQueue = DispatchQueue.main
    ) {
        self.videoPlaylistsUseCase = videoPlaylistsUseCase
        self.thumbnailUseCase = thumbnailUseCase
        self.videoPlaylistContentUseCase = videoPlaylistContentUseCase
        self.syncModel = syncModel
        self.alertViewModel = alertViewModel
        self.monitorSortOrderChangedDispatchQueue = monitorSortOrderChangedDispatchQueue
        syncModel.$shouldShowAddNewPlaylistAlert.assign(to: &$shouldShowAddNewPlaylistAlert)
        
        self.alertViewModel.action = { [weak self] newVideoPlaylistName in
            self?.createUserVideoPlaylist(with: newVideoPlaylistName)
        }
        
        assignVideoPlaylistNameValidator()
        listenSearchTextChange()
        monitorSortOrderChanged()
    }
    
    private func assignVideoPlaylistNameValidator() {
        let validator = VideoPlaylistNameValidator(existingVideoPlaylistNames: { [weak self] in
            self?.videoPlaylistNames ?? []
        })
        alertViewModel.validator = { try? validator.validateWhenCreated(with: $0) }
    }
    
    @MainActor
    func onViewAppeared() async {
        await loadVideoPlaylists()
        await monitorVideoPlaylists()
    }
    
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
        async let systemVideoPlaylists = loadSystemVideoPlaylists()
        async let userVideoPlaylists = videoPlaylistsUseCase.userVideoPlaylists()
        
        let playlists = await systemVideoPlaylists + userVideoPlaylists
        videoPlaylists = VideoPlaylistsSorter.sort(playlists, by: sortOrder ?? syncModel.videoRevampVideoPlaylistsSortOrderType)
    }
    
    private func loadSystemVideoPlaylists() async -> [VideoPlaylistEntity] {
        guard let videoPlaylist = try? await videoPlaylistsUseCase.systemVideoPlaylists() else {
            return []
        }
        
        return videoPlaylist
            .compactMap { videoPlaylist in
                guard videoPlaylist.isSystemVideoPlaylist else {
                    return nil
                }
                return VideoPlaylistEntity(
                    id: videoPlaylist.id,
                    name: Strings.Localizable.Videos.Tab.Playlist.Content.PlaylistCell.Title.favorites,
                    count: videoPlaylist.count,
                    type: videoPlaylist.type,
                    creationTime: videoPlaylist.creationTime,
                    modificationTime: videoPlaylist.modificationTime
                )
            }
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
                    self.loadVideoPlaylistsOnSearchTextChangedTask = Task {
                        guard !Task.isCancelled else {
                            return
                        }
                        await self.loadVideoPlaylists()
                    }
                } else {
                    self.videoPlaylists = self.videoPlaylists.filter { $0.name.lowercased().contains(value.lowercased()) }
                }
            }
            .store(in: &subscriptions)
    }
    
    func createUserVideoPlaylist(with name: String?) {
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
    }
    
    private func cancelCreateVideoPlaylistTask() {
        createVideoPlaylistTask?.cancel()
        createVideoPlaylistTask = nil
    }
    
    @MainActor
    func didPickVideosToBeIncludedInNewlyCreatedPlaylist(videos: [NodeEntity]) {
        shouldShowVideoPlaylistPicker = false
        addVideosToNewlyCreatedVideoPlaylist(videos: videos)
    }
    
    private func addVideosToNewlyCreatedVideoPlaylist(videos: [NodeEntity]) {
        // will be do on differentt ticket. Out of this ticket scope.
    }
    
    func didSelectMoreOptionForItem(_ selectedVideoPlaylistEntity: VideoPlaylistEntity) {
        self.selectedVideoPlaylistEntity = selectedVideoPlaylistEntity
        isSheetPresented = true
    }
    
    func didSelectActionSheetMenuAction(_ contextAction: ContextAction) {
        switch contextAction.type {
        case .rename:
            break // CC-7328
        case .deletePlaylist:
            break // CC-7278
        }
    }
}
