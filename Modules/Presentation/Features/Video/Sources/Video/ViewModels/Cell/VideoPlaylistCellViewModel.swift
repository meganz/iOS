import MEGADomain
import MEGASwiftUI
import SwiftUI

final class VideoPlaylistCellViewModel: ObservableObject {
    
    private let thumbnailUseCase: any ThumbnailUseCaseProtocol
    private(set) var videoPlaylistEntity: VideoPlaylistEntity
    private var videos: [NodeEntity]
    private let onTapMoreOptions: (_ node: VideoPlaylistEntity) -> Void
    
    @Published var previewEntity: VideoPlaylistCellPreviewEntity
    
    init(
        thumbnailUseCase: some ThumbnailUseCaseProtocol,
        videoPlaylistEntity: VideoPlaylistEntity,
        videos: [NodeEntity],
        onTapMoreOptions: @escaping (_ node: VideoPlaylistEntity) -> Void
    ) {
        self.thumbnailUseCase = thumbnailUseCase
        self.videoPlaylistEntity = videoPlaylistEntity
        self.videos = videos
        self.onTapMoreOptions = onTapMoreOptions
        
        let playlistDuration = videos
            .map { $0.duration }
            .reduce(0, +)
        let durationText = VideoDurationFormatter.formatDuration(seconds: UInt(max(playlistDuration, 0)))
        
        let cachedContainers = videos
            .filter { $0.hasThumbnail }
            .map { (video: NodeEntity) -> any ImageContaining in
                guard let cachedContainer = thumbnailUseCase.cachedThumbnailContainer(for: video, type: .thumbnail) else {
                    let placeholderContainer = ImageContainer(image: Image(systemName: "square.fill"), type: .placeholder)
                    return placeholderContainer
                }
                return cachedContainer
            }
        
        previewEntity = videoPlaylistEntity.toVideoPlaylistCellPreviewEntity(thumbnailContainers: cachedContainers, durationText: durationText)
    }
    
    func attemptLoadThumbnail() async {
        var remoteContainers = [any ImageContaining]()
        for video in videos where video.hasThumbnail {
            guard let container = await loadThumbnailContainerFromRemote(for: video) else {
                return
            }
            remoteContainers.append(container)
        }
        
        let playlistDuration = videos
            .map { $0.duration }
            .reduce(0, +)
        let durationText = VideoDurationFormatter.formatDuration(seconds: UInt(max(playlistDuration, 0)))
        
        previewEntity = videoPlaylistEntity.toVideoPlaylistCellPreviewEntity(
            thumbnailContainers: remoteContainers,
            durationText: durationText
        )
    }
    
    func onTappedMoreOptions() {
        onTapMoreOptions(videoPlaylistEntity)
    }
    
    private func loadThumbnailContainerFromRemote(for video: NodeEntity) async -> (any ImageContaining)? {
        guard let container = try? await thumbnailUseCase.loadThumbnailContainer(for: video, type: .thumbnail) else {
            return nil
        }
        return container
    }
}
