import AsyncAlgorithms
import Combine
import MEGADomain
import MEGASwiftUI

final class VideoPlaylistContentViewModel: ObservableObject {
    
    private var videoPlaylistEntity: VideoPlaylistEntity
    private let videoPlaylistContentsUseCase: any VideoPlaylistContentsUseCaseProtocol
    private(set) var thumbnailUseCase: any ThumbnailUseCaseProtocol
    private let videoPlaylistThumbnailLoader: any VideoPlaylistThumbnailLoaderProtocol
    
    @Published var videos: [NodeEntity] = []
    @Published var headerPreviewEntity: VideoPlaylistCellPreviewEntity = .placeholder
    @Published var secondaryInformationViewType: VideoPlaylistCellViewModel.SecondaryInformationViewType = .emptyPlaylist
    @Published var shouldPopScreen = false
    @Published var shouldShowError = false
    
    init(
        videoPlaylistEntity: VideoPlaylistEntity,
        videoPlaylistContentsUseCase: some VideoPlaylistContentsUseCaseProtocol,
        thumbnailUseCase: some ThumbnailUseCaseProtocol,
        videoPlaylistThumbnailLoader: some VideoPlaylistThumbnailLoaderProtocol
    ) {
        self.videoPlaylistEntity = videoPlaylistEntity
        self.videoPlaylistContentsUseCase = videoPlaylistContentsUseCase
        self.thumbnailUseCase = thumbnailUseCase
        self.videoPlaylistThumbnailLoader = videoPlaylistThumbnailLoader
    }
    
    @MainActor
    func onViewAppeared() async {
        await monitorUserVideoPlaylist()
    }
    
    @MainActor
    private func monitorUserVideoPlaylist() async {
        do {
            let anyVideoPlaylistUpdateSequence = combineLatest(
                videoPlaylistContentsUseCase.monitorVideoPlaylist(for: videoPlaylistEntity),
                videoPlaylistContentsUseCase.monitorUserVideoPlaylistContent(for: videoPlaylistEntity)
            )
            
            for try await (videoPlaylist, videos) in anyVideoPlaylistUpdateSequence {
                guard !Task.isCancelled else {
                    break
                }
                self.videoPlaylistEntity = videoPlaylist
                self.videos = videos
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
}
