import AsyncAlgorithms
@preconcurrency import Combine
import Foundation
import MEGAAppPresentation
import MEGAAssets
import MEGADomain
import MEGASwift
import MEGASwiftUI
import SwiftUI

/// Identity used to key a photo cell's load `.task(id:)` hooks. Includes thumbnail readiness so the
/// load restarts when a node's thumbnail/preview becomes available after an initial `noThumbnail`.
struct NodeLoadIdentity: Hashable {
    let handle: HandleEntity
    let hasThumbnail: Bool
    let hasPreview: Bool
}

@MainActor
open class PhotoCellViewModel: ObservableObject {

    // MARK: public state
    public let duration: String
    public let isVideo: Bool
    
    @Published var currentZoomScaleFactor: PhotoLibraryZoomState.ScaleFactor
    @Published public var thumbnailContainer: any ImageContaining
    @Published public var isSelected: Bool = false {
        didSet {
            guard !isPlaceholder else { return }
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
    
    @Published public private(set) var shouldShowFavorite: Bool = false

    /// True when the cell renders inside the rolled-back album layout, so it should
    /// keep the legacy favorite-badge styling (small heart, gradient overlay, no
    /// pill background) instead of the masonry/revamp pill heart.
    let useLegacyFavoriteStyle: Bool
    
    var shouldApplyContentOpacity: Bool {
        editMode.isEditing && isSelectionLimitReached && !isSelected
    }
    
    private var isPlaceholder: Bool { photo.isTimelinePlaceholder }

    /// Identity for the view's load `.task(id:)` hooks (thumbnail + sensitivity monitoring).
    /// It changes when the cell's underlying node changes — most importantly when a timeline
    /// placeholder is hydrated into its real node *in place* via `reconfigureItems`, which reuses
    /// the cell and its SwiftUI view identity, so a plain `.task` would keep the placeholder's
    /// no-op load and never start the real one. Keying the tasks on this restarts them against the
    /// real node.
    ///
    /// Thumbnail *readiness* is part of the identity on purpose: a just-uploaded node arrives with
    /// `hasThumbnail == false` and its first load throws `noThumbnail`; when the thumbnail later
    /// becomes available the node is patched in place (same handle) and reconfigured — but that
    /// reuses the SwiftUI view, so a handle-only identity would NOT restart the (already-finished)
    /// load and the cell would stay a placeholder until scrolled off and back. Folding
    /// `hasThumbnail`/`hasPreview` in restarts the load exactly when readiness flips.
    var nodeLoadIdentity: NodeLoadIdentity {
        NodeLoadIdentity(handle: photo.handle, hasThumbnail: photo.hasThumbnail, hasPreview: photo.hasPreview)
    }

    // MARK: private state
    private let photo: NodeEntity
    private let thumbnailLoader: any ThumbnailLoaderProtocol
    private let sensitiveNodeUseCase: (any SensitiveNodeUseCaseProtocol)?
    private let selection: PhotoSelection
    private let configuration: ContentLibraries.Configuration
    /// Set only for a placeholder cell on a screen that answers by position; nil leaves it inert.
    private let placeholderSelection: PlaceholderCellSelection?
    private var subscriptions = Set<AnyCancellable>()
    
    public init(photo: NodeEntity,
                viewModel: PhotoLibraryModeAllViewModel,
                thumbnailLoader: some ThumbnailLoaderProtocol,
                sensitiveNodeUseCase: (any SensitiveNodeUseCaseProtocol)?,
                configuration: ContentLibraries.Configuration = ContentLibraries.configuration,
                placeholderSelection: PlaceholderCellSelection? = nil) {
        self.photo = photo
        self.selection = viewModel.libraryViewModel.selection
        self.placeholderSelection = photo.isTimelinePlaceholder ? placeholderSelection : nil
        self.thumbnailLoader = thumbnailLoader
        self.sensitiveNodeUseCase = sensitiveNodeUseCase
        self.configuration = configuration
        self.useLegacyFavoriteStyle = viewModel.libraryViewModel.contentMode == .album
            && !AlbumLayoutGate.isMasonryLayoutEnabled
        currentZoomScaleFactor = viewModel.zoomState.scaleFactor
        isVideo = photo.mediaType == .video
        duration = photo.duration >= 0 ? TimeInterval(photo.duration).timeString : ""
        
        let type: ThumbnailTypeEntity = viewModel.zoomState.scaleFactor == .one ? .preview : .thumbnail
        if photo.isTimelinePlaceholder {
            thumbnailContainer = ImageContainer(image: MEGAAssets.Image.filetypeImages, type: .placeholder)
        } else {
            thumbnailContainer = thumbnailLoader.initialImage(for: photo, type: type)
        }
        
        configZoomState(with: viewModel.$zoomState)
        configSelection()
        
        subscribeToPhotoFavouritesChange(with: viewModel.$zoomState)
        self.selection.$editMode.assign(to: &$editMode)
    }
    
    // MARK: Internal
                
    func select() {
        guard !selection.isSelectionDisabled else { return }
        // A placeholder's mark is not a node in the selection, so it is neither toggled here nor
        // counted against a limit — the screens that set one have no placeholders anyway.
        guard !isPlaceholder else {
            guard editMode.isEditing,
                  let placeholderSelection,
                  let position = placeholderSelection.position() else { return }
            placeholderSelection.handler.apply(.tap, at: position)
            return
        }
        if editMode.isEditing && (isSelected || !isSelectionLimitReached) {
            isSelected.toggle()
        } else {
            selection.isItemSelectedAfterLimitReached = true
        }
    }

    func handleLongPress() {
        guard !selection.isSelectionDisabled, !editMode.isEditing else { return }
        guard !isPlaceholder else {
            guard let placeholderSelection,
                  let position = placeholderSelection.position() else { return }
            selection.editMode = .active
            placeholderSelection.handler.apply(.longPress, at: position)
            placeholderSelection.handler.markRecentlyLongPressed(at: position)
            return
        }
        selection.editMode = .active
        selection.selectPhoto(photo)
        selection.markRecentlyLongPressed(photo.handle)
    }
    
    // MARK: Thumbnail/Preview Loading
    public func startLoadingThumbnail() async {
        guard !isPlaceholder else { return }
        let thumbnailTypeSequence = $currentZoomScaleFactor
            .values
            .map { zoomScaleFactor -> ThumbnailTypeEntity in
                zoomScaleFactor == .one ? .preview : .thumbnail
            }
            .removeDuplicates()
        
        do {
            for await thumbnailType in thumbnailTypeSequence {
                try Task.checkCancellation()
                switch (thumbnailType, thumbnailContainer.type) {
                case (.thumbnail, .thumbnail), (.preview, .preview):
                    break
                default:
                    try await loadThumbnail(type: thumbnailType)
                }
            }
        } catch {
            MEGALogDebug("[\(type(of: self))] Cancelled loading thumbnail for \(photo.handle)")
        }
    }
    
    func monitorInheritedSensitivityChanges() async {
        guard !isPlaceholder,
              sensitiveNodeUseCase != nil,
              !photo.isMarkedSensitive,
              await $thumbnailContainer.values.contains(where: { @Sendable in $0.type != .placeholder }) else { return }
        
        do {
            for try await isInheritingSensitivity in monitorInheritedSensitivity(for: photo) {
                updateThumbnailContainerIfNeeded(thumbnailContainer.toSensitiveImageContaining(isSensitive: isInheritingSensitivity))
            }
        } catch {
            MEGALogError("[\(type(of: self))] failed to retrieve inherited sensitivity for photo: \(error.localizedDescription)")
        }
    }
    
    private func loadThumbnail(type: ThumbnailTypeEntity) async throws {
        for await imageContainer in try await thumbnailLoader.loadImage(for: photo, type: type) {
            updateThumbnailContainerIfNeeded(imageContainer)
        }
    }
    
    private func updateThumbnailContainerIfNeeded(_ container: any ImageContaining) {
        guard !isShowingThumbnail(container) else { return }
        updateThumbnailContainer(container)
    }
    
    private func updateThumbnailContainer(_ container: any ImageContaining) {
        thumbnailContainer = container
    }

    private func isShowingThumbnail(_ container: some ImageContaining) -> Bool {
        thumbnailContainer.isEqual(container)
    }
    
    private func configSelection() {
        if let placeholderSelection {
            configPlaceholderSelection(placeholderSelection)
        } else {
            configHandleSelection()
        }
        
        if let isSelectionLimitReachedPublisher = selection.isSelectionLimitReachedPublisher {
            isSelectionLimitReachedPublisher
                .assign(to: &$isSelectionLimitReached)
        }
    }

    private func configHandleSelection() {
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
        
        selection.$photos
            .map { [handle = photo.handle] photos in
                photos[handle] != nil
            }
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .assign(to: &$isSelected)
    }
    
    /// A placeholder has no handle for `selection.photos` to key it by, so its mark is asked for by
    /// position and re-asked on every change. It renders as any other selected cell does.
    ///
    /// This replaces the handle subscription rather than joining it: a synthetic handle is never in
    /// `photos`, so that one would clear the mark on the next change to the committed selection.
    private func configPlaceholderSelection(_ placeholderSelection: PlaceholderCellSelection) {
        updateSelectionFromPlaceholderHandler()
        selection
            .$allSelected
            .dropFirst()
            .filter { [weak self] allSelected in
                !allSelected && self?.isSelected == true
            }
            .map { _ in false }
            .assign(to: &$isSelected)
        // No main-queue hop: the handler is main-actor bound, so the mark lands in the same turn
        // as the interaction that caused it.
        placeholderSelection.handler.selectionDidChangePublisher
            .sink { [weak self] in
                self?.updateSelectionFromPlaceholderHandler()
            }
            .store(in: &subscriptions)
    }

    private func updateSelectionFromPlaceholderHandler() {
        guard let placeholderSelection, let position = placeholderSelection.position() else { return }
        let selected = placeholderSelection.handler.isSelected(at: position)
        if isSelected != selected {
            isSelected = selected
        }
    }

    private func configZoomState(with zoomStatePublisher: some Publisher<PhotoLibraryZoomState, Never>) {
        zoomStatePublisher
            .map(\.scaleFactor)
            .receive(on: DispatchQueue.main)
            .assign(to: &$currentZoomScaleFactor)
    }
    
    private func subscribeToPhotoFavouritesChange(with zoomStatePublisher: some Publisher<PhotoLibraryZoomState, Never>) {
        zoomStatePublisher
            .compactMap { [weak self] zoomState -> Bool? in
                guard let self else { return nil }
                return canShowFavorite(photo: photo, atCurrentZoom: zoomState.scaleFactor, withMaximumZoom: zoomState.maximumScaleFactor)
            }
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .assign(to: &$shouldShowFavorite)
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

    /// Async sequence will yield inherited sensitivity changes. It will immediately yield the current inherited sensitivity since it could have changed since thumbnail loaded
    /// - Parameters:
    ///   - photo: Photo NodeEntity to monitor
    private func monitorInheritedSensitivity(for photo: NodeEntity) -> AnyAsyncThrowingSequence<Bool, any Error> {
        guard let sensitiveNodeUseCase else { return EmptyAsyncSequence().eraseToAnyAsyncThrowingSequence() }
        
        return sensitiveNodeUseCase.monitorInheritedSensitivity(for: photo)
            .prepend {
                try await sensitiveNodeUseCase.isInheritingSensitivity(node: photo)
            }
            .eraseToAnyAsyncThrowingSequence()
    }
}
