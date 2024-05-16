import MEGADomain
import MEGASwiftUI
import SwiftUI

final class VideoPlaylistCellViewModel: ObservableObject {
    
    private let thumbnailUseCase: any ThumbnailUseCaseProtocol
    private let videoPlaylistEntity: VideoPlaylistEntity
    private(set) var videoPlaylistContentUseCase: any VideoPlaylistContentsUseCaseProtocol
    private let onTapMoreOptions: (_ node: VideoPlaylistEntity) -> Void
    
    @Published var previewEntity: VideoPlaylistCellPreviewEntity
    @Published var secondaryInformationViewType: VideoPlaylistCellViewModel.SecondaryInformationViewType = .emptyPlaylist
    
    init(
        thumbnailUseCase: some ThumbnailUseCaseProtocol,
        videoPlaylistContentUseCase: some VideoPlaylistContentsUseCaseProtocol,
        videoPlaylistEntity: VideoPlaylistEntity,
        onTapMoreOptions: @escaping (_ node: VideoPlaylistEntity) -> Void
    ) {
        self.thumbnailUseCase = thumbnailUseCase
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
        let imageContainers = await withTaskGroup(of: (order: Int, imageContainer: (any ImageContaining)?).self) { group -> [(any ImageContaining)?] in
            for (index, video) in videos.enumerated() where video.hasThumbnail {
                group.addTask {
                    let container = await self.imageContainer(from: video)
                    return (order: index, imageContainer: container)
                }
            }
            
            var results = [(order: Int, imageContainer: (any ImageContaining)?)]()
            for await result in group {
                results.append(result)
            }
            
            return results
                .sorted { $0.order < $1.order }
                .compactMap(\.imageContainer)
        }
        
        previewEntity = videoPlaylistEntity.toVideoPlaylistCellPreviewEntity(
            thumbnailContainers: imageContainers.compactMap { $0 },
            durationText: durationText(from: videos)
        )
        
        secondaryInformationViewType = videos.count == 0 ? .emptyPlaylist : .information
    }
    
    private func imageContainer(from video: NodeEntity) async -> (any ImageContaining)? {
        guard let cachedContainer = cachedImageContainer(for: video) else {
            return await remoteImageContainer(for: video)
        }
        
        return cachedContainer
    }
    
    private func cachedImageContainer(for video: NodeEntity) -> (any ImageContaining)? {
        guard let cachedContainer = thumbnailUseCase.cachedThumbnailContainer(for: video, type: .thumbnail) else {
            return nil
        }
        return cachedContainer
    }
    
    private func remoteImageContainer(for video: NodeEntity) async -> (any ImageContaining)? {
        guard let container = try? await thumbnailUseCase.loadThumbnailContainer(for: video, type: .thumbnail) else {
            return nil
        }
        return container
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
