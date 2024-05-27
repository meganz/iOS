import Combine
import MEGADomain
import MEGASwiftUI

final class VideoPlaylistContentViewModel: ObservableObject {
    
    private let videoPlaylistEntity: VideoPlaylistEntity
    private let videoPlaylistContentsUseCase: any VideoPlaylistContentsUseCaseProtocol
    private(set) var thumbnailUseCase: any ThumbnailUseCaseProtocol
    private let videoPlaylistThumbnailLoader: any VideoPlaylistThumbnailLoaderProtocol
    
    @Published var videos: [NodeEntity] = []
    @Published var headerPreviewEntity: VideoPlaylistCellPreviewEntity = .placeholder
    @Published var secondaryInformationViewType: VideoPlaylistCellViewModel.SecondaryInformationViewType = .emptyPlaylist
    
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
        videos = await videos(for: videoPlaylistEntity)
        await loadThumbnails(for: videos)
    }
    
    @MainActor
    private func loadThumbnails(for videos: [NodeEntity]) async {
        let imageContainers = await videoPlaylistThumbnailLoader.loadThumbnails(for: videos)
        
        headerPreviewEntity = videoPlaylistEntity.toVideoPlaylistCellPreviewEntity(
            thumbnailContainers: imageContainers.compactMap { $0 },
            durationText: durationText(from: videos)
        )
        
        secondaryInformationViewType = videos.count == 0 ? .emptyPlaylist : .information
    }
    
    private func videos(for videoPlaylist: VideoPlaylistEntity) async -> [NodeEntity] {
        guard let videos = try? await videoPlaylistContentsUseCase.videos(in: videoPlaylistEntity) else {
            // Better to log in future MR. Currently MEGALogger is from main module.
            return []
        }
        return videos
    }
    
    private func durationText(from videos: [NodeEntity]) -> String {
        let playlistDuration = videos
            .map(\.duration)
            .reduce(0, +)
        
        return VideoDurationFormatter.formatDuration(seconds: UInt(max(playlistDuration, 0)))
    }
}
