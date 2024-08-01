import AsyncAlgorithms
import Combine
import MEGAAnalyticsiOS
import MEGADomain
import MEGAPresentation
import MEGASwift
import MEGASwiftUI
import SwiftUI

final class AlbumCellViewModel: ObservableObject {
    let album: AlbumEntity
    let selection: AlbumSelection
    let isLinkShared: Bool
    
    @Published var numberOfNodes: Int = 0
    @Published var thumbnailContainer: any ImageContaining
    @Published var isLoading: Bool = false
    @Published var title: String = ""
    @Published var isSelected: Bool = false {
        didSet {
            if isSelected != oldValue && selection.isAlbumSelected(album) != isSelected {
                selection.albums[album.id] = isSelected ? album : nil
            }
        }
    }

    @Published var editMode: EditMode = .inactive {
        willSet {
            opacity = newValue.isEditing && album.systemAlbum ? 0.5 : 1.0
            shouldShowEditStateOpacity = newValue.isEditing && !album.systemAlbum ? 1.0 : 0.0
        }
    }
    
    @Published var shouldShowEditStateOpacity: Double = 0.0
    @Published var opacity: Double = 1.0
    @Binding var selectedAlbum: AlbumEntity?
    
    private let thumbnailLoader: any ThumbnailLoaderProtocol
    private let monitorAlbumsUseCase: any MonitorAlbumsUseCaseProtocol
    private let nodeUseCase: any NodeUseCaseProtocol
    private let sensitiveNodeUseCase: any SensitiveNodeUseCaseProtocol
    private let contentConsumptionUserAttributeUseCase: any ContentConsumptionUserAttributeUseCaseProtocol
    private let tracker: any AnalyticsTracking
    private let featureFlagProvider: any FeatureFlagProviderProtocol
    
    private var subscriptions = Set<AnyCancellable>()
    private var albumMetaData: AlbumMetaDataEntity?
    
    private var isEditing: Bool {
        selection.editMode.isEditing
    }
    
    init(
        thumbnailLoader: some ThumbnailLoaderProtocol,
        monitorAlbumsUseCase: some MonitorAlbumsUseCaseProtocol,
        nodeUseCase: some NodeUseCaseProtocol,
        sensitiveNodeUseCase: some SensitiveNodeUseCaseProtocol,
        contentConsumptionUserAttributeUseCase: some ContentConsumptionUserAttributeUseCaseProtocol,
        album: AlbumEntity,
        selection: AlbumSelection,
        tracker: some AnalyticsTracking = DIContainer.tracker,
        selectedAlbum: Binding<AlbumEntity?>,
        featureFlagProvider: some FeatureFlagProviderProtocol = DIContainer.featureFlagProvider
    ) {
        self.thumbnailLoader = thumbnailLoader
        self.monitorAlbumsUseCase = monitorAlbumsUseCase
        self.nodeUseCase = nodeUseCase
        self.sensitiveNodeUseCase = sensitiveNodeUseCase
        self.contentConsumptionUserAttributeUseCase = contentConsumptionUserAttributeUseCase
        self.album = album
        self.selection = selection
        self.tracker = tracker
        _selectedAlbum = selectedAlbum
        self.featureFlagProvider = featureFlagProvider
        
        title = album.name
        numberOfNodes = album.count
        isLinkShared = album.isLinkShared
        
        if let coverNode = album.coverNode {
            thumbnailContainer = thumbnailLoader.initialImage(for: coverNode, type: .thumbnail, placeholder: { Image(.placeholder) })
        } else {
            thumbnailContainer = ImageContainer(image: Image(.placeholder), type: .placeholder)
        }
        
        configSelection()
        subscribeToEditMode()
    }
    
    @MainActor
    func loadAlbumThumbnail() async {
        guard let coverNode = album.coverNode,
              thumbnailContainer.type == .placeholder else {
            return
        }
        if !isLoading {
            isLoading.toggle()
        }
        await loadThumbnail(for: coverNode)
    }
    
    func onAlbumTap() {
        guard !(isEditing && album.systemAlbum) else { return }
        
        if isEditing {
            isSelected.toggle()
        } else {
            selectedAlbum = album
        }
        
        trackAnalytics()
    }
    
    @MainActor
    func monitorAlbumPhotos() async {
        guard featureFlagProvider.isFeatureFlagEnabled(for: .albumPhotoCache),
              album.type == .user else { return }
        
        for await albumPhotos in await monitorAlbumsUseCase.monitorUserAlbumPhotos(for: album,
                                                                                   excludeSensitives: excludeSensitives(),
                                                                                   includeSensitiveInherited: featureFlagProvider.isFeatureFlagEnabled(for: .hiddenNodes)) {
            numberOfNodes = albumPhotos.count
            
            guard shouldUseDefaultCover(photos: albumPhotos) else {
                await loadAlbumCoverIfNeeded(from: albumPhotos)
                continue
            }
            await setDefaultAlbumCover(albumPhotos)
            albumMetaData = await albumPhotos.makeAlbumMetaData()
        }
    }
    
    /// Monitor inherited sensitivity changes for album cover photo
    @MainActor
    func monitorCoverPhotoSensitivity() async {
        guard featureFlagProvider.isFeatureFlagEnabled(for: .hiddenNodes),
              let coverNode = album.coverNode,
              !coverNode.isMarkedSensitive else { return }
        // Wait for initial thumbnail to load with sensitivity before checking inherited sensitivity updates
        _ = await $thumbnailContainer.values.contains(where: { $0.type != .placeholder })
        do {
            for try await isInheritingSensitivity in sensitiveNodeUseCase.inheritedSensitivity(for: coverNode) {
                let sensitiveImageContaining = thumbnailContainer.toSensitiveImageContaining(isSensitive: isInheritingSensitivity)
                guard !thumbnailContainer.isEqual(sensitiveImageContaining) else { continue }
                thumbnailContainer = sensitiveImageContaining
            }
        } catch {
            MEGALogError("[AlbumCellViewModel] failed to retrieve inherited sensitivity for album cover: \(error.localizedDescription)")
        }
    }
    
    // MARK: Private
    
    @MainActor
    private func setDefaultAlbumCover(_ photos: [AlbumPhotoEntity]) async {
        guard let latestPhoto = photos.latestModifiedPhoto() else {
            if thumbnailContainer.type != .placeholder {
                thumbnailContainer = ImageContainer(image: Image(.placeholder), type: .placeholder)
            }
            return
        }
        
        await loadThumbnail(for: latestPhoto)
    }
    
    @MainActor
    private func loadThumbnail(for node: NodeEntity) async {
        guard let imageContainer = try? await thumbnailLoader.loadImage(for: node, type: .thumbnail) else {
            isLoading = false
            return
        }
        
        thumbnailContainer = imageContainer
        isLoading = false
    }
    
    private func configSelection() {
        selection
            .$allSelected
            .dropFirst()
            .filter { [weak self] in
                self?.isSelected != $0
            }
            .assign(to: &$isSelected)
    }
    
    private func subscribeToEditMode() {
        selection.$editMode
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.editMode = $0
            }
            .store(in: &subscriptions)
    }
    
    private func shouldUseDefaultCover(photos: [AlbumPhotoEntity]) -> Bool {
        guard let albumCover = album.coverNode else {
            return true
        }
        return nodeUseCase.isInRubbishBin(nodeHandle: albumCover.handle) ||
        photos.notContains(where: { $0.photo.handle == albumCover.handle })
    }
    
    @MainActor
    private func loadAlbumCoverIfNeeded(from photos: [AlbumPhotoEntity]) async {
        guard let cover = album.coverNode,
              let imageContainer = try? await thumbnailLoader.loadImage(for: cover, type: .thumbnail),
              !thumbnailContainer.isEqual(imageContainer) else {
            return
        }
        thumbnailContainer = imageContainer
    }
    
    @MainActor
    private func excludeSensitives() async -> Bool {
        if featureFlagProvider.isFeatureFlagEnabled(for: .hiddenNodes) {
            await !contentConsumptionUserAttributeUseCase.fetchSensitiveAttribute().showHiddenNodes
        } else {
            false
        }
    }
    
    private func trackAnalytics() {
        let selectionType: AlbumSelected.SelectionType = if isEditing {
            isSelected ? .multiadd : .multiremove
        } else {
            .single
        }
        let event = if featureFlagProvider.isFeatureFlagEnabled(for: .albumPhotoCache) {
            AlbumSelectedEvent(
                selectionType: selectionType,
                imageCount: albumMetaData?.imageCount.toKotlinInt(),
                videoCount: albumMetaData?.videoCount.toKotlinInt()
            )
        } else {
            album.makeAlbumSelectedEvent(
                selectionType: selectionType)
        }
        tracker.trackAnalyticsEvent(with: event)
    }
}

private extension SensitiveNodeUseCaseProtocol {
    /// Async sequence will immediately yield inherited sensitivity and then any updated changes
    /// It will immediately yield the current inherited sensitivity since it could have changed since thumbnail loaded
    /// - Parameters:
    ///   - node: NodeEntity to monitor
    /// - Returns: An `AnyAsyncThrowingSequence<Bool, any Error>` yielding inherited sensitivity changes
    func inheritedSensitivity(for coverNode: NodeEntity) -> AnyAsyncThrowingSequence<Bool, any Error> {
        monitorInheritedSensitivity(for: coverNode)
            .prepend {
                try await isInheritingSensitivity(node: coverNode)
            }
            .removeDuplicates()
            .eraseToAnyAsyncThrowingSequence()
    }
}

private extension Sequence where Element == AlbumPhotoEntity {
    func makeAlbumMetaData() async -> AlbumMetaDataEntity {
        reduce(AlbumMetaDataEntity(imageCount: 0, videoCount: 0)) { counts, photo in
            if photo.photo.name.fileExtensionGroup.isImage {
                .init(imageCount: counts.imageCount + 1, videoCount: counts.videoCount)
            } else {
                .init(imageCount: counts.imageCount, videoCount: counts.videoCount + 1)
            }
        }
    }
}
