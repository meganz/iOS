import Combine
import Foundation
import MEGADomain
import MEGAPresentation
import MEGASwift
import MEGASwiftUI
import SwiftUI

class PhotoCellViewModel: ObservableObject {

    // MARK: public state
    let duration: String
    let isVideo: Bool
    let isSensitive: Bool
    
    @Published var currentZoomScaleFactor: PhotoLibraryZoomState.ScaleFactor
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
        
    // MARK: private state
    private let photo: NodeEntity
    private let thumbnailUseCase: any ThumbnailUseCaseProtocol
    private let selection: PhotoSelection
    private var subscriptions = Set<AnyCancellable>()
    
    init(photo: NodeEntity,
         viewModel: PhotoLibraryModeAllViewModel,
         thumbnailUseCase: some ThumbnailUseCaseProtocol,
         featureFlagProvider: some FeatureFlagProviderProtocol = DIContainer.featureFlagProvider) {
        self.photo = photo
        self.selection = viewModel.libraryViewModel.selection
        self.thumbnailUseCase = thumbnailUseCase
        currentZoomScaleFactor = viewModel.zoomState.scaleFactor
        isVideo = photo.mediaType == .video
        duration = photo.duration >= 0 ? TimeInterval(photo.duration).timeString : ""
        isSensitive = featureFlagProvider.isFeatureFlagEnabled(for: .hiddenNodes) && photo.isMarkedSensitive
        
        let type: ThumbnailTypeEntity = viewModel.zoomState.scaleFactor == .one ? .preview : .thumbnail
        if let container = thumbnailUseCase.cachedThumbnailContainer(for: photo, type: type) {
            thumbnailContainer = container
        } else {
            let placeholderFileTypeResource = FileTypes().fileTypeResource(forFileName: photo.name)
            let placeholder = ImageContainer(image: Image(placeholderFileTypeResource), type: .placeholder)
            thumbnailContainer = placeholder
        }
        configZoomState(with: viewModel.$zoomState)
        configSelection()
        
        subscribeToPhotoFavouritesChange(with: viewModel.$zoomState)
        self.selection.$editMode.assign(to: &$editMode)
    }
    
    // MARK: Internal
                
    func select() {
        guard !selection.isSelectionDisabled else { return }
        if editMode.isEditing && (isSelected || !isSelectionLimitReached) {
            isSelected.toggle()
        } else {
            selection.isItemSelectedAfterLimitReached = true
        }
    }
    
    // MARK: Thumbnail/Preview Loading
    func startLoadingThumbnail() async {
        let thumbnailTypePublisher: some Publisher<ThumbnailTypeEntity, Never> = $currentZoomScaleFactor
            .map { zoomScaleFactor -> ThumbnailTypeEntity in
                zoomScaleFactor == .one ? .preview : .thumbnail
            }
            .removeDuplicates()
        
        do {
            for await thumbnailType in thumbnailTypePublisher.values {
                try Task.checkCancellation()
                switch (thumbnailType, thumbnailContainer.type) {
                case (.thumbnail, .thumbnail), (.preview, .preview):
                    break
                default:
                    try await loadThumbnail(type: thumbnailType)
                }
            }
        } catch {
            MEGALogDebug("[PhotoCellViewModel] Cancelled loading thumbnail for \(photo.handle)")
        }
    }
    
    private func loadThumbnail(type: ThumbnailTypeEntity) async throws {
        switch type {
        case .thumbnail:
            if let container = try? await thumbnailUseCase.loadThumbnailContainer(for: photo, type: .thumbnail) {
                await updateThumbnailContainerIfNeeded(container)
            }
        case .preview, .original:
            if let container = thumbnailUseCase.cachedThumbnailContainer(for: photo, type: .preview) {
                return await updateThumbnailContainerIfNeeded(container)
            }
            
            for try await imageContainer in thumbnailUseCase
                .requestPreview(for: photo)
                .compactMap({ $0.toURLImageContainer()}) {
                
                try Task.checkCancellation()
                await updateThumbnailContainerIfNeeded(imageContainer)
            }
        }
    }
    
    private func updateThumbnailContainerIfNeeded(_ container: any ImageContaining) async {
        guard !isShowingThumbnail(container) else { return }
        await updateThumbnailContainer(container)
    }
    
    @MainActor
    private func updateThumbnailContainer(_ container: any ImageContaining) {
        thumbnailContainer = container
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
    
    private func configZoomState(with zoomStatePublisher: some Publisher<PhotoLibraryZoomState, Never>) {
        zoomStatePublisher
            .map(\.scaleFactor)
            .receive(on: DispatchQueue.main)
            .assign(to: &$currentZoomScaleFactor)
    }
    
    private func subscribeToPhotoFavouritesChange(with zoomStatePublisher: some Publisher<PhotoLibraryZoomState, Never>) {
    
        if #available(iOS 16.0, *) {
            zoomStatePublisher
                .map(\.scaleFactor)
                .compactMap { [weak self] currentZoomScale -> Bool? in
                    guard let self else { return nil }
                    return canShowFavorite(photo: photo, atCurrentZoom: currentZoomScale)
                }
                .removeDuplicates()
                .receive(on: DispatchQueue.main)
                .assign(to: &$shouldShowFavorite)
        } else {
            zoomStatePublisher
                .map(\.scaleFactor)
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
    
    /// Returns whether or not the given NodeEntity should indicate if it has been favourited.
    /// - Parameters:
    ///   - photo: NodeEntity from which we compare its .isFavourtite to determine if it has been favourited.
    ///   - scale: The current zoom level for the application feature
    ///   - scaleLimit: The maximum allowed zoom level, before we do not allow the indicating if it should present any indication of favouritism. This is typically based on the not having enough visual space to present the favourite indicator.
    /// - Returns: Boolean - Representing if the given photo should present a favourite indicator.
    private func canShowFavorite(photo: NodeEntity, atCurrentZoom scale: PhotoLibraryZoomState.ScaleFactor, withMaximumZoom scaleLimit: PhotoLibraryZoomState.ScaleFactor = .thirteen) -> Bool {
        photo.isFavourite && scale.rawValue < scaleLimit.rawValue
    }
}
