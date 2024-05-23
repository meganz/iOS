import Combine
import Foundation
import MEGADomain
import MEGAL10n
import MEGASwiftUI

final class VideoPlaylistsViewModel: ObservableObject {
    private let videoPlaylistsUseCase: any VideoPlaylistUseCaseProtocol
    private(set) var thumbnailUseCase: any ThumbnailUseCaseProtocol
    private(set) var videoPlaylistContentUseCase: any VideoPlaylistContentsUseCaseProtocol
    
    @Published var videoPlaylists = [VideoPlaylistEntity]()
    @Published var shouldShowAddNewPlaylistAlert = false
    @Published var playlistName = ""
    
    private var videoPlaylistNames: [String] {
        videoPlaylists.map(\.name)
    }
    
    private(set) var alertViewModel: TextFieldAlertViewModel
    
    private var createVideoPlaylistTask: Task<Void, Never>?
    
    init(
        videoPlaylistsUseCase: some VideoPlaylistUseCaseProtocol,
        thumbnailUseCase: some ThumbnailUseCaseProtocol,
        videoPlaylistContentUseCase: some VideoPlaylistContentsUseCaseProtocol,
        syncModel: VideoRevampSyncModel,
        alertViewModel: TextFieldAlertViewModel
    ) {
        self.videoPlaylistsUseCase = videoPlaylistsUseCase
        self.thumbnailUseCase = thumbnailUseCase
        self.videoPlaylistContentUseCase = videoPlaylistContentUseCase
        self.alertViewModel = alertViewModel
        syncModel.$shouldShowAddNewPlaylistAlert.assign(to: &$shouldShowAddNewPlaylistAlert)
        
        self.alertViewModel.action = { [weak self] newVideoPlaylistName in
            self?.createUserVideoPlaylist(with: newVideoPlaylistName)
        }
        
        assignVideoPlaylistNameValidator()
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
    private func loadVideoPlaylists() async {
        async let systemVideoPlaylists = loadSystemVideoPlaylists()
        async let userVideoPlaylists = videoPlaylistsUseCase.userVideoPlaylists()
        
        videoPlaylists = await systemVideoPlaylists + userVideoPlaylists
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
                    type: videoPlaylist.type
                )
            }
    }
    
    private func createUserVideoPlaylist(with name: String?) {
        createVideoPlaylistTask = Task {
            do {
                let mappedName = VideoPlaylistNameCreationMapper.videoPlaylistName(from: name, from: videoPlaylistNames)
                _ = try await videoPlaylistsUseCase.createVideoPlaylist(mappedName)
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
}
