import MEGADomain
import MEGAPresentation
import MEGASwiftUI
import SwiftUI

@MainActor
public final class VideoPlaylistCellViewModel: ObservableObject {
    
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
    
    func onViewAppear() async {
        for await videos in videoPlaylistContentUseCase.monitorUserVideoPlaylistContent(for: videoPlaylistEntity) {
            await loadThumbnails(for: videos)
        }
    }
    
    private func loadThumbnails(for videos: [NodeEntity]) async {
        let sortOrder = sortOrderPreferenceUseCase.sortOrder(for: .videoPlaylistContent)
        let sortedVideos = await VideoPlaylistContentSorter.sort(videos, by: sortOrder)
        let thumbnail = await videoPlaylistThumbnailLoader.loadThumbnails(for: sortedVideos)
        
        previewEntity = videoPlaylistEntity.toVideoPlaylistCellPreviewEntity(
            videoPlaylistThumbnail: thumbnail,
            videosCount: videos.count,
            durationText: await videos.durationText()
        )
        
        secondaryInformationViewType = videos.count == 0 ? .emptyPlaylist : .information
        
        isLoading = false
    }
        
    func onTappedMoreOptions() {
        onTapMoreOptions(videoPlaylistEntity)
    }
    
    public enum SecondaryInformationViewType: Equatable {
        case emptyPlaylist
        case information
    }
}
