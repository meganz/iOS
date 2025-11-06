import AsyncAlgorithms
@preconcurrency import Combine
import Foundation
import MEGAAppPresentation
import MEGADomain
import MEGASwift
import MEGASwiftUI
import SwiftUI

@MainActor
open class PhotoCellViewModel: ObservableObject {

    // MARK: public state
    public let duration: String
    public let isVideo: Bool
    
    @Published var currentZoomScaleFactor: PhotoLibraryZoomState.ScaleFactor
    @Published public var thumbnailContainer: any ImageContaining
    @Published public var isSelected: Bool = false {
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
    
    @Published public private(set) var shouldShowFavorite: Bool = false
    
    var shouldApplyContentOpacity: Bool {
        editMode.isEditing && isSelectionLimitReached && !isSelected
    }
        
    // MARK: private state
    private let photo: NodeEntity
    private let thumbnailLoader: any ThumbnailLoaderProtocol
    private let nodeUseCase: (any NodeUseCaseProtocol)?
    private let sensitiveNodeUseCase: (any SensitiveNodeUseCaseProtocol)?
    private let remoteFeatureFlagUseCase: any RemoteFeatureFlagUseCaseProtocol
    private let selection: PhotoSelection
    private var subscriptions = Set<AnyCancellable>()
    
    public init(photo: NodeEntity,
                viewModel: PhotoLibraryModeAllViewModel,
                thumbnailLoader: some ThumbnailLoaderProtocol,
                nodeUseCase: (any NodeUseCaseProtocol)?,
                sensitiveNodeUseCase: (any SensitiveNodeUseCaseProtocol)?,
                remoteFeatureFlagUseCase: some RemoteFeatureFlagUseCaseProtocol = DIContainer.remoteFeatureFlagUseCase) {
        self.photo = photo
        self.selection = viewModel.libraryViewModel.selection
        self.thumbnailLoader = thumbnailLoader
        self.nodeUseCase = nodeUseCase
        self.sensitiveNodeUseCase = sensitiveNodeUseCase
        self.remoteFeatureFlagUseCase = remoteFeatureFlagUseCase
        currentZoomScaleFactor = viewModel.zoomState.scaleFactor
        isVideo = photo.mediaType == .video
        duration = photo.duration >= 0 ? TimeInterval(photo.duration).timeString : ""
        
        let type: ThumbnailTypeEntity = viewModel.zoomState.scaleFactor == .one ? .preview : .thumbnail
        thumbnailContainer = thumbnailLoader.initialImage(for: photo, type: type)
        
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
    public func startLoadingThumbnail() async {
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
        guard remoteFeatureFlagUseCase.isFeatureFlagEnabled(for: .hiddenNodes),
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
    
    /// Monitor photo node and inherited sensitivity changes
    /// - Important: This is only required for iOS 15 since the photo library is using the `PhotoScrollPosition` as an `id` see `PhotoLibraryModeAllGridView`
    func monitorPhotoSensitivityChanges() async {
        guard remoteFeatureFlagUseCase.isFeatureFlagEnabled(for: .hiddenNodes),
              nodeUseCase != nil,
              sensitiveNodeUseCase != nil else { return }
        // Don't monitor node sensitivity changes if the thumbnail is placeholder. This will wait infinitely if the thumbnail is placeholder
        _ = await $thumbnailContainer.values.contains(where: { @Sendable in $0.type != .placeholder })
        
        do {
            for try await isSensitive in photoSensitivityChanges(for: photo) {
                updateThumbnailContainerIfNeeded(thumbnailContainer.toSensitiveImageContaining(isSensitive: isSensitive))
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
    
    /// Async sequence will yield photo sensitivity and inherited sensitivity changes. It will immediately yield the current photo sensitivity if true otherwise the  inherited sensitivity since it could have changed since thumbnail loaded
    /// - Parameters:
    ///   - photo: Photo NodeEntity to monitor
    private func photoSensitivityChanges(for photo: NodeEntity) -> AnyAsyncThrowingSequence<Bool, any Error> {
        
        guard let nodeUseCase,
              let sensitiveNodeUseCase else {
            return EmptyAsyncSequence().eraseToAnyAsyncThrowingSequence()
        }
        
        // Need to fetch the latest version of the node.
        // This is a architecture bug with the SwiftUI version iOS 15 and below
        // The NodeEntity does not update in this model, due to the way the SwiftUI view has been built
        // If used in iOS16 +, this is not an issue as this VM gets recreated on reloads and scrolling away
        let node = nodeUseCase.nodeForHandle(photo.handle) ?? photo
        
        return combineLatest(
            sensitiveNodeUseCase.sensitivityChanges(for: node).prepend(node.isMarkedSensitive),
            monitorInheritedSensitivity(for: node)
        )
        .map { isPhotoSensitive, isInheritingSensitive in
            if isPhotoSensitive {
                true
            } else {
                isInheritingSensitive
            }
        }
        .removeDuplicates()
        .eraseToAnyAsyncThrowingSequence()
    }
}
