import Combine
import Foundation
import MEGADomain
import MEGASwift
import MEGASwiftUI
import SwiftUI

class PhotoCellViewModel: ObservableObject {

    // MARK: public state
    var duration: String
    var isVideo: Bool
    
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
            if #available(iOS 15.0, *) {
                try await startLoadingThumbnailAsyncPublisher(thumbnailTypePublisher: thumbnailTypePublisher)
            } else {
                try await startLoadingThumbnailAsyncStream(thumbnailTypePublisher: thumbnailTypePublisher)
            }
        } catch {
            MEGALogDebug("[PhotoCellViewModel] Cancelled loading thumbnail for \(photo.handle)")
        }
    }
    
    @available(iOS 15.0, *)
    private func startLoadingThumbnailAsyncPublisher(thumbnailTypePublisher: some Publisher<ThumbnailTypeEntity, Never>) async throws {
        for await thumbnailType in thumbnailTypePublisher.values {
            try Task.checkCancellation()
            switch (thumbnailType, thumbnailContainer.type) {
            case (.thumbnail, .thumbnail), (.preview, .preview):
                break
            default:
                try await loadThumbnail(for: thumbnailType)
            }
        }
    }
    
    private func startLoadingThumbnailAsyncStream(thumbnailTypePublisher: some Publisher<ThumbnailTypeEntity, Never>) async throws {
        
        var subscription: AnyCancellable?
        let thumbnailTypeStream = AsyncStream(ThumbnailTypeEntity.self) { continuation in
            subscription = thumbnailTypePublisher
                .sink(
                    receiveCompletion: { _ in continuation.finish() },
                    receiveValue: { thumbnailType in continuation.yield(thumbnailType) })
        }
        
        for await thumbnailType in thumbnailTypeStream {
            try Task.checkCancellation()
            switch (thumbnailType, thumbnailContainer.type) {
            case (.thumbnail, .thumbnail), (.preview, .preview):
                break
            default:
                try await loadThumbnail(for: thumbnailType)
            }
        }
        
        subscription?.cancel()
        subscription = nil
    }

    private func loadThumbnail(for type: ThumbnailTypeEntity) async throws {
        switch type {
        case .thumbnail:
            if let container = thumbnailUseCase.cachedThumbnailContainer(for: photo, type: .thumbnail) {
                await updateThumbnailContainerIfNeeded(container)
            } else if let container = try? await thumbnailUseCase.loadThumbnailContainer(for: photo, type: .thumbnail) {
                await updateThumbnailContainerIfNeeded(container)
            }
        case .preview, .original:
            if let container = thumbnailUseCase.cachedThumbnailContainer(for: photo, type: .preview) {
                await updateThumbnailContainerIfNeeded(container)
            } else {
                if let container = thumbnailUseCase.cachedThumbnailContainer(for: photo, type: .thumbnail) {
                    await updateThumbnailContainerIfNeeded(container)
                }
                
                let requestPreviewPublisher = thumbnailUseCase
                    .requestPreview(for: photo)
                    .map { $0.toURLImageContainer() }
                    .replaceError(with: nil)
                    .compactMap { $0 }
                
                if #available(iOS 15.0, *) {
                    try await requestPreviewAsyncPublisher(requestPreviewPublisher: requestPreviewPublisher)
                } else {
                    try await requestPreviewAsyncStream(requestPreviewPublisher: requestPreviewPublisher)
                }
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
    
    @available(iOS 15.0, *)
    private func requestPreviewAsyncPublisher(requestPreviewPublisher: some Publisher<URLImageContainer, Never>) async throws {
        for await container in requestPreviewPublisher.values {
            try Task.checkCancellation()
            await updateThumbnailContainerIfNeeded(container)
        }
    }
    
    private func requestPreviewAsyncStream(requestPreviewPublisher: some Publisher<URLImageContainer, Never>) async throws {
        
        var subscription: AnyCancellable?
        let values = AsyncStream { continuation in
            subscription = requestPreviewPublisher
                .sink(
                    receiveCompletion: { _ in continuation.finish() },
                    receiveValue: { container in continuation.yield(container) })
        }
        
        for await container in values {
            try Task.checkCancellation()
            await updateThumbnailContainerIfNeeded(container)
        }
        
        subscription?.cancel()
        subscription = nil
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
