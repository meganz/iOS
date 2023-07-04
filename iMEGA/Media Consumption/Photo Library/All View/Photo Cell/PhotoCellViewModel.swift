import Combine
import Foundation
import MEGADomain
import MEGASwift
import MEGASwiftUI
import SwiftUI

class PhotoCellViewModel: ObservableObject {
    private let photo: NodeEntity
    private let thumbnailUseCase: any ThumbnailUseCaseProtocol
    private let selection: PhotoSelection
    private var subscriptions = Set<AnyCancellable>()
    
    var thumbnailLoadingTask: Task<Void, Never>?
    var duration: String
    var isVideo: Bool
    
    @Published var currentZoomScaleFactor: PhotoLibraryZoomState.ScaleFactor {
        didSet {
            if currentZoomScaleFactor == .one || oldValue == .one {
                startLoadingThumbnail()
            }
        }
    }
    
    @Published var thumbnailContainer: any ImageContaining
    @Published var isSelected: Bool = false {
        didSet {
            if isSelected != oldValue && selection.isPhotoSelected(photo) != isSelected {
                selection.photos[photo.handle] = isSelected ? photo : nil
            }
        }
    }
    
    @Published var editMode: EditMode = .inactive
    @Published private(set) var isSelectionLimitReached: Bool = false
    
    var shouldShowEditState: Bool {
        editMode.isEditing && currentZoomScaleFactor != .thirteen
    }
    
    @Published private(set) var shouldShowFavorite: Bool = false
    
    var shouldApplyContentOpacity: Bool {
        editMode.isEditing && isSelectionLimitReached && !isSelected
    }
    
    init(photo: NodeEntity,
         viewModel: PhotoLibraryModeAllViewModel,
         thumbnailUseCase: any ThumbnailUseCaseProtocol) {
        self.photo = photo
        self.selection = viewModel.libraryViewModel.selection
        self.thumbnailUseCase = thumbnailUseCase
        currentZoomScaleFactor = viewModel.zoomState.scaleFactor
        isVideo = photo.mediaType == .video
        duration = photo.duration >= 0 ? TimeInterval(photo.duration).timeString : ""
        let type: ThumbnailTypeEntity = viewModel.zoomState.scaleFactor == .one ? .preview : .thumbnail
        if let container = thumbnailUseCase.cachedThumbnailContainer(for: photo, type: type) {
            thumbnailContainer = container
        } else {
            let placeholderFileType = FileTypes().fileType(forFileName: photo.name)
            let placeholder = ImageContainer(image: Image(placeholderFileType), type: .placeholder)
            thumbnailContainer = placeholder
        }
        configZoomState(with: viewModel)
        configSelection()
        subscribeToPhotoFavouritesChange()
        self.selection.$editMode.assign(to: &$editMode)
    }
    
    // MARK: Internal
    func startLoadingThumbnail() {
        if currentZoomScaleFactor == .one && thumbnailContainer.type == .preview {
            return
        } else if currentZoomScaleFactor != .one && thumbnailContainer.type == .thumbnail {
            return
        } else {
            thumbnailLoadingTask = Task {
                await loadThumbnail()
            }
        }
    }
    
    func cancelLoadingThumbnail() {
        thumbnailLoadingTask?.cancel()
    }
    
    func select() {
        guard !selection.isSelectionDisabled else { return }
        if editMode.isEditing && (isSelected || !isSelectionLimitReached) {
            isSelected.toggle()
        } else {
            selection.isItemSelectedAfterLimitReached = true
        }
    }
    
    // MARK: Private
    private func loadThumbnail() async {
        let type: ThumbnailTypeEntity = currentZoomScaleFactor == .one ? .preview : .thumbnail
        switch type {
        case .thumbnail:
            if let container = thumbnailUseCase.cachedThumbnailContainer(for: photo, type: .thumbnail) {
                await updateThumbailContainerIfNeeded(container)
            } else if let container = try? await thumbnailUseCase.loadThumbnailContainer(for: photo, type: .thumbnail) {
                await updateThumbailContainerIfNeeded(container)
            }
        case .preview, .original:
            if let container = thumbnailUseCase.cachedThumbnailContainer(for: photo, type: .preview) {
                await updateThumbailContainerIfNeeded(container)
            } else {
                if let container = thumbnailUseCase.cachedThumbnailContainer(for: photo, type: .thumbnail) {
                    await updateThumbailContainerIfNeeded(container)
                }
                
                requestPreview()
            }
        }
    }
    
    private func updateThumbailContainerIfNeeded(_ container: any ImageContaining) async {
        guard !isShowingThumbnail(container) else { return }
        await updateThumbailContainer(container)
    }
    
    @MainActor
    private func updateThumbailContainer(_ container: any ImageContaining) {
        thumbnailContainer = container
    }
    
    private func requestPreview() {
        thumbnailUseCase
            .requestPreview(for: photo)
            .map {
                $0.toURLImageContainer()
            }
            .replaceError(with: nil)
            .compactMap { $0 }
            .filter { [weak self] in
                self?.isShowingThumbnail($0) == false
            }
            .receive(on: DispatchQueue.main)
            .assign(to: &$thumbnailContainer)
    }
    
    private func isShowingThumbnail(_ container: some ImageContaining) -> Bool {
        thumbnailContainer.isEqual(container)
    }
    
    private func configSelection() {
        selection
            .$allSelected
            .dropFirst()
            .filter { [weak self] in
                self?.isSelected != $0
            }
            .assign(to: &$isSelected)
        
        if selection.editMode.isEditing {
            isSelected = selection.isPhotoSelected(photo)
        }
        
        if let isSelectionLimitReachedPublisher = selection.isSelectionLimitReachedPublisher {
            isSelectionLimitReachedPublisher
                .assign(to: &$isSelectionLimitReached)
        }
    }
    
    private func configZoomState(with viewModel: PhotoLibraryModeAllViewModel) {
        viewModel
            .$zoomState
            .sink { [weak self] in
                self?.currentZoomScaleFactor = $0.scaleFactor
            }
            .store(in: &subscriptions)
    }
    
    private func subscribeToPhotoFavouritesChange() {
    
        if #available(iOS 16.0, *) {
            $currentZoomScaleFactor
                .compactMap { [weak self] currentZoomScale -> Bool? in
                    guard let self else { return nil }
                    return canShowFavorite(photo: photo, atCurrentZoom: currentZoomScale)
                }
                .removeDuplicates()
                .receive(on: DispatchQueue.main)
                .assign(to: &$shouldShowFavorite)
        } else {
            $currentZoomScaleFactor
                .combineLatest(NotificationCenter.default.publisher(for: .didPhotoFavouritesChange).compactMap { $0.object as? [NodeEntity] })
                .sink { [weak self] zoomFactor, updatedNodes in
                    guard let self,
                          let updateNode = updatedNodes.first(where: { $0 == self.photo }) else {
                        return
                    }
                    shouldShowFavorite = updateNode.isFavourite && zoomFactor.rawValue < PhotoLibraryZoomState.ScaleFactor.thirteen.rawValue
                }
                .store(in: &subscriptions)
        }
    }
    
    /// Returns wheather or not the given NodeEntity shold indicate if it has been favourited.
    /// - Parameters:
    ///   - photo: NodeEntity from which we compare its .isFavourtite to determine if it has been favourited.
    ///   - scale: The current zoom level for the application feature
    ///   - scaleLimit: The maximum allowed zoom level, before we do not allow the indicating if it should present any indication of favourtism. This is typically based on the not having enough visual space to present the favourite indicator.
    /// - Returns: Boolean - Representing if the given photo should present a favourite indicator.
    private func canShowFavorite(photo: NodeEntity, atCurrentZoom scale: PhotoLibraryZoomState.ScaleFactor, withMaximumZoom scaleLimit: PhotoLibraryZoomState.ScaleFactor = .thirteen) -> Bool {
        photo.isFavourite && scale.rawValue < scaleLimit.rawValue
    }
}
