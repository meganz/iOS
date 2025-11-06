import MEGAAppPresentation
import MEGADomain
import MEGASwiftUI
import SwiftUI

@MainActor
public final class VideoPlaylistCellViewModel: ObservableObject {
    
    private let videoPlaylistThumbnailLoader: any VideoPlaylistThumbnailLoaderProtocol
    private(set) var videoPlaylistEntity: VideoPlaylistEntity
    private(set) var videoPlaylistContentUseCase: any VideoPlaylistContentsUseCaseProtocol
    private let setSelection: SetSelection
    private let sortOrderPreferenceUseCase: any SortOrderPreferenceUseCaseProtocol
    private let onTapMoreOptions: (_ node: VideoPlaylistEntity) -> Void
    
    @Published var previewEntity: VideoPlaylistCellPreviewEntity
    @Published var secondaryInformationViewType: VideoPlaylistCellViewModel.SecondaryInformationViewType = .emptyPlaylist
    @Published var isLoading = true
    @Published var isSelectionEnabled = false
    @Published var isSelected = false
    @Published var isDisabled = false
    
    init(
        videoPlaylistThumbnailLoader: some VideoPlaylistThumbnailLoaderProtocol,
        videoPlaylistContentUseCase: some VideoPlaylistContentsUseCaseProtocol,
        sortOrderPreferenceUseCase: some SortOrderPreferenceUseCaseProtocol,
        videoPlaylistEntity: VideoPlaylistEntity,
        setSelection: SetSelection,
        onTapMoreOptions: @escaping (_ node: VideoPlaylistEntity) -> Void
    ) {
        self.videoPlaylistThumbnailLoader = videoPlaylistThumbnailLoader
        self.videoPlaylistContentUseCase = videoPlaylistContentUseCase
        self.sortOrderPreferenceUseCase = sortOrderPreferenceUseCase
        self.videoPlaylistEntity = videoPlaylistEntity
        self.setSelection = setSelection
        self.onTapMoreOptions = onTapMoreOptions
        self.previewEntity = .placeholder
        
        setSelection.$editMode
            .map( \.isEditing)
            .assign(to: &$isSelectionEnabled)
        
        setSelection.$selectedSets
            .map { $0.contains(where: { $0 == videoPlaylistEntity.setIdentifier }) }
            .removeDuplicates()
            .assign(to: &$isSelected)
        
        setSelection.shouldShowDisabled(for: videoPlaylistEntity.setIdentifier)
            .assign(to: &$isDisabled)
    }
    
    func onViewAppear() async {
        for await videos in videoPlaylistContentUseCase.monitorUserVideoPlaylistContent(for: videoPlaylistEntity) {
            await loadThumbnails(for: videos)
        }
    }
    
    func onTappedMoreOptions() {
        onTapMoreOptions(videoPlaylistEntity)
    }
    
    func onItemSelected() {
        setSelection.toggle(videoPlaylistEntity.setIdentifier)
    }
    
    // MARK: - Private functions
    
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
    
    public enum SecondaryInformationViewType: Equatable {
        case emptyPlaylist
        case information
    }
}
