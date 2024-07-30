import MEGADomain
import MEGAPresentation
import MEGASwiftUI
import SwiftUI

final class VideoPlaylistCellViewModel: ObservableObject {
    
    private let videoPlaylistThumbnailLoader: any VideoPlaylistThumbnailLoaderProtocol
    private(set) var videoPlaylistEntity: VideoPlaylistEntity
    private(set) var videoPlaylistContentUseCase: any VideoPlaylistContentsUseCaseProtocol
    private let sortOrderPreferenceUseCase: any SortOrderPreferenceUseCaseProtocol
    private let onTapMoreOptions: (_ node: VideoPlaylistEntity) -> Void
    
    @Published var previewEntity: VideoPlaylistCellPreviewEntity
    @Published var secondaryInformationViewType: VideoPlaylistCellViewModel.SecondaryInformationViewType = .emptyPlaylist
    @Published var isLoading = true
    
    init(
        videoPlaylistThumbnailLoader: some VideoPlaylistThumbnailLoaderProtocol,
        videoPlaylistContentUseCase: some VideoPlaylistContentsUseCaseProtocol,
        sortOrderPreferenceUseCase: some SortOrderPreferenceUseCaseProtocol,
        videoPlaylistEntity: VideoPlaylistEntity,
        onTapMoreOptions: @escaping (_ node: VideoPlaylistEntity) -> Void
    ) {
        self.videoPlaylistThumbnailLoader = videoPlaylistThumbnailLoader
        self.videoPlaylistContentUseCase = videoPlaylistContentUseCase
        self.sortOrderPreferenceUseCase = sortOrderPreferenceUseCase
        self.videoPlaylistEntity = videoPlaylistEntity
        self.onTapMoreOptions = onTapMoreOptions
        self.previewEntity = .placeholder
    }
    
    @MainActor
    func onViewAppear() async {
        for await videos in videoPlaylistContentUseCase.monitorUserVideoPlaylistContent(for: videoPlaylistEntity) {
            await loadThumbnails(for: videos)
        }
    }
    
    @MainActor
    private func loadThumbnails(for videos: [NodeEntity]) async {
        let sortOrder = sortOrderPreferenceUseCase.sortOrder(for: .videoPlaylistContent)
        let sortedVideos = await VideoPlaylistContentSorter.sort(videos, by: sortOrder)
        let imageContainers = await videoPlaylistThumbnailLoader.loadThumbnails(for: sortedVideos)
        
        previewEntity = videoPlaylistEntity.toVideoPlaylistCellPreviewEntity(
            thumbnailContainers: imageContainers,
            videosCount: videos.count,
            durationText: durationText(from: videos)
        )
        
        secondaryInformationViewType = videos.count == 0 ? .emptyPlaylist : .information
        
        isLoading = false
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
