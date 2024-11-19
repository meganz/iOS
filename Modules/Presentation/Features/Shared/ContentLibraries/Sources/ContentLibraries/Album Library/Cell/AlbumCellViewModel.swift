import AsyncAlgorithms
@preconcurrency import Combine
import MEGAAnalyticsiOS
import MEGAAssets
import MEGADomain
import MEGAPresentation
import MEGASwift
import MEGASwiftUI
import SwiftUI

@MainActor
public final class AlbumCellViewModel: ObservableObject, Identifiable {
    nonisolated public var id: SetHandleEntity {
        album.id
    }
    
    public let album: AlbumEntity
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
    
    var isOnTapGestureEnabled: Bool {
        isEditing || onAlbumSelected != nil
    }
    
    private let thumbnailLoader: any ThumbnailLoaderProtocol
    private let monitorUserAlbumPhotosUseCase: any MonitorUserAlbumPhotosUseCaseProtocol
    private let nodeUseCase: any NodeUseCaseProtocol
    private let sensitiveNodeUseCase: any SensitiveNodeUseCaseProtocol
    private let sensitiveDisplayPreferenceUseCase: any SensitiveDisplayPreferenceUseCaseProtocol
    private let albumCoverUseCase: any AlbumCoverUseCaseProtocol
    private let tracker: any AnalyticsTracking
    private let remoteFeatureFlagUseCase: any RemoteFeatureFlagUseCaseProtocol
    private let onAlbumSelected: ((AlbumEntity) -> Void)?
    private let configuration: ContentLibraries.Configuration
    
    private var subscriptions = Set<AnyCancellable>()
    private var albumMetaData: AlbumMetaDataEntity?
    
    private var isEditing: Bool {
        selection.editMode.isEditing
    }
    
    public init(
        thumbnailLoader: some ThumbnailLoaderProtocol,
        monitorUserAlbumPhotosUseCase: some MonitorUserAlbumPhotosUseCaseProtocol,
        nodeUseCase: some NodeUseCaseProtocol,
        sensitiveNodeUseCase: some SensitiveNodeUseCaseProtocol,
        sensitiveDisplayPreferenceUseCase: some SensitiveDisplayPreferenceUseCaseProtocol,
        albumCoverUseCase: some AlbumCoverUseCaseProtocol,
        album: AlbumEntity,
        selection: AlbumSelection,
        tracker: some AnalyticsTracking = DIContainer.tracker,
        onAlbumSelected: ((AlbumEntity) -> Void)? = nil,
        remoteFeatureFlagUseCase: some RemoteFeatureFlagUseCaseProtocol = DIContainer.remoteFeatureFlagUseCase,
        configuration: ContentLibraries.Configuration = ContentLibraries.configuration
    ) {
        self.thumbnailLoader = thumbnailLoader
        self.monitorUserAlbumPhotosUseCase = monitorUserAlbumPhotosUseCase
        self.nodeUseCase = nodeUseCase
        self.sensitiveNodeUseCase = sensitiveNodeUseCase
        self.sensitiveDisplayPreferenceUseCase = sensitiveDisplayPreferenceUseCase
        self.albumCoverUseCase = albumCoverUseCase
        self.album = album
        self.selection = selection
        self.tracker = tracker
        self.onAlbumSelected = onAlbumSelected
        self.remoteFeatureFlagUseCase = remoteFeatureFlagUseCase
        self.configuration = configuration
        
        title = album.name
        numberOfNodes = album.count
        isLinkShared = album.isLinkShared
        
        if let coverNode = album.coverNode {
            thumbnailContainer = thumbnailLoader.initialImage(
                for: coverNode,
                type: .thumbnail,
                placeholder: { MEGAAssetsImageProvider.image(named: .placeholder) })
        } else {
            thumbnailContainer = ImageContainer(
                image: MEGAAssetsImageProvider.image(named: .placeholder),
                type: .placeholder)
        }
        
        configSelection()
        subscribeToEditMode()
    }
    
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
            onAlbumSelected?(album)
        }
        
        trackAnalytics()
    }
    
    func monitorAlbumPhotos() async {
        guard configuration.isAlbumPerformanceImprovementsEnabled(),
              album.type == .user else { return }
        let excludeSensitives = await sensitiveDisplayPreferenceUseCase.excludeSensitives()
        for await albumPhotos in await monitorUserAlbumPhotosUseCase.monitorUserAlbumPhotos(
            for: album, excludeSensitives: excludeSensitives) {
            
            numberOfNodes = albumPhotos.count
            await loadAlbumCover(from: albumPhotos)
            albumMetaData = await albumPhotos.makeAlbumMetaData()
        }
    }
    
    /// Monitor inherited sensitivity changes for album cover photo
    func monitorCoverPhotoSensitivity() async {
        guard remoteFeatureFlagUseCase.isFeatureFlagEnabled(for: .hiddenNodes),
              let coverNode = album.coverNode,
              !coverNode.isMarkedSensitive else { return }
        // Wait for initial thumbnail to load with sensitivity before checking inherited sensitivity updates
        _ = await $thumbnailContainer.values.contains(where: { @Sendable in $0.type != .placeholder })
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
    
    private func loadAlbumCover(from photos: [AlbumPhotoEntity]) async {
        let imageContainer = if let albumCover = await albumCoverUseCase.albumCover(for: album, photos: photos) {
            try? await thumbnailLoader.loadImage(for: albumCover, type: .thumbnail)
        } else {
            ImageContainer(
                image: MEGAAssetsImageProvider.image(named: .placeholder),
                type: .placeholder)
        }
        guard let imageContainer,
              !thumbnailContainer.isEqual(imageContainer) else { return }
        thumbnailContainer = imageContainer
    }
    
    private func trackAnalytics() {
        let selectionType: AlbumSelected.SelectionType = if isEditing {
            isSelected ? .multiadd : .multiremove
        } else {
            .single
        }
        let event = if configuration.isAlbumPerformanceImprovementsEnabled() {
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

extension AlbumCellViewModel: Equatable {
    nonisolated public static func == (lhs: AlbumCellViewModel, rhs: AlbumCellViewModel) -> Bool {
        lhs.album == rhs.album
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
