import MEGADomain
import MEGASwiftUI
import SwiftUI

final class VideoCellViewModel: ObservableObject {
    
    private let thumbnailUseCase: any ThumbnailUseCaseProtocol
    private let nodeEntity: NodeEntity
    private let onTapMoreOptions: (_ node: NodeEntity) -> Void
    private let selection: VideoSelection
    
    @Published var previewEntity: VideoCellPreviewEntity
    @Published var isSelected = false
    
    init(
        thumbnailUseCase: some ThumbnailUseCaseProtocol,
        nodeEntity: NodeEntity,
        selection: VideoSelection,
        onTapMoreOptions: @escaping (_ node: NodeEntity) -> Void
    ) {
        self.thumbnailUseCase = thumbnailUseCase
        self.nodeEntity = nodeEntity
        self.selection = selection
        self.onTapMoreOptions = onTapMoreOptions
        
        guard let cachedContainer = thumbnailUseCase.cachedThumbnailContainer(for: nodeEntity, type: .thumbnail) else {
            let placeholderContainer = ImageContainer(image: Image(systemName: "square.fill"), type: .placeholder)
            previewEntity = nodeEntity.toVideoCellPreviewEntity(thumbnailContainer: placeholderContainer)
            return
        }
        previewEntity = nodeEntity.toVideoCellPreviewEntity(thumbnailContainer: cachedContainer)
        
        listenToVideoSelection()
    }
    
    func attemptLoadThumbnail() async {
        guard
            previewEntity.imageContainer.type == .placeholder,
            let remoteContainer = await loadThumbnailContainerFromRemote() else {
            return
        }
        previewEntity = nodeEntity.toVideoCellPreviewEntity(thumbnailContainer: remoteContainer)
    }
    
    func onTappedMoreOptions() {
        onTapMoreOptions(nodeEntity)
    }
    
    func onTappedCheckMark() {
        guard
            selection.editMode.isEditing,
            !selection.isSelectionDisabled
        else {
            return
        }
        
        selection.toggleSelection(for: nodeEntity)
    }
    
    private func loadThumbnailContainerFromRemote() async -> (any ImageContaining)? {
        guard let container = try? await thumbnailUseCase.loadThumbnailContainer(for: nodeEntity, type: .thumbnail) else {
            return nil
        }
        return container
    }
    
    private func listenToVideoSelection() {
        selection
            .isVideoSelectedPublisher(for: nodeEntity)
            .assign(to: &$isSelected)
    }
}
