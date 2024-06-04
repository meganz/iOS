import MEGADomain
import MEGASwiftUI
import SwiftUI

final class VideoPlaylistCellViewModel: ObservableObject {
    
    private let thumbnailUseCase: any ThumbnailUseCaseProtocol
    private let videoPlaylistThumbnailLoader: any VideoPlaylistThumbnailLoaderProtocol
    private(set) var videoPlaylistEntity: VideoPlaylistEntity
    private(set) var videoPlaylistContentUseCase: any VideoPlaylistContentsUseCaseProtocol
    private let onTapMoreOptions: (_ node: VideoPlaylistEntity) -> Void
    
    @Published var previewEntity: VideoPlaylistCellPreviewEntity
    @Published var secondaryInformationViewType: VideoPlaylistCellViewModel.SecondaryInformationViewType = .emptyPlaylist
    
    init(
        thumbnailUseCase: some ThumbnailUseCaseProtocol,
        videoPlaylistThumbnailLoader: some VideoPlaylistThumbnailLoaderProtocol,
        videoPlaylistContentUseCase: some VideoPlaylistContentsUseCaseProtocol,
        videoPlaylistEntity: VideoPlaylistEntity,
        onTapMoreOptions: @escaping (_ node: VideoPlaylistEntity) -> Void
    ) {
        self.thumbnailUseCase = thumbnailUseCase
        self.videoPlaylistThumbnailLoader = videoPlaylistThumbnailLoader
        self.videoPlaylistContentUseCase = videoPlaylistContentUseCase
        self.videoPlaylistEntity = videoPlaylistEntity
        self.onTapMoreOptions = onTapMoreOptions
        self.previewEntity = .placeholder
    }
    
    @MainActor
    func onViewAppear() async {
        let videos = await videos(for: videoPlaylistEntity)
        try? Task.checkCancellation()
        
        await loadThumbnails(for: videos)
    }
    
    @MainActor
    private func loadThumbnails(for videos: [NodeEntity]) async {
        let imageContainers = await videoPlaylistThumbnailLoader.loadThumbnails(for: videos)
        
        previewEntity = videoPlaylistEntity.toVideoPlaylistCellPreviewEntity(
            thumbnailContainers: imageContainers.compactMap { $0 },
            videosCount: videos.count,
            durationText: durationText(from: videos)
        )
        
        secondaryInformationViewType = videos.count == 0 ? .emptyPlaylist : .information
    }
    
    private func videos(for videoPlaylist: VideoPlaylistEntity) async -> [NodeEntity] {
        guard let videos = try? await videoPlaylistContentUseCase.videos(in: videoPlaylistEntity) else {
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
    
    func onTappedMoreOptions() {
        onTapMoreOptions(videoPlaylistEntity)
    }
    
    enum SecondaryInformationViewType: Equatable {
        case emptyPlaylist
        case information
    }
}
