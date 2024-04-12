import Combine
import MEGADomain
import MEGAPresentation
import MEGASwiftUI
import SwiftUI

final class AlbumCellViewModel: ObservableObject {
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
    
    let album: AlbumEntity
    private let thumbnailUseCase: any ThumbnailUseCaseProtocol
    private let monitorAlbumsUseCase: any MonitorAlbumsUseCaseProtocol
    private let nodeUseCase: any NodeUseCaseProtocol
    private let tracker: any AnalyticsTracking
    private let featureFlagProvider: any FeatureFlagProviderProtocol
    
    let selection: AlbumSelection
    
    private var subscriptions = Set<AnyCancellable>()
    private var albumMetaData: AlbumMetaDataEntity?
    
    private var isEditing: Bool {
        selection.editMode.isEditing
    }
    
    let isLinkShared: Bool
    
    init(
        thumbnailUseCase: some ThumbnailUseCaseProtocol,
        monitorAlbumsUseCase: some MonitorAlbumsUseCaseProtocol,
        nodeUseCase: some NodeUseCaseProtocol,
        album: AlbumEntity,
        selection: AlbumSelection,
        tracker: some AnalyticsTracking = DIContainer.tracker,
        featureFlagProvider: some FeatureFlagProviderProtocol = DIContainer.featureFlagProvider
    ) {
        self.thumbnailUseCase = thumbnailUseCase
        self.monitorAlbumsUseCase = monitorAlbumsUseCase
        self.nodeUseCase = nodeUseCase
        self.album = album
        self.selection = selection
        self.tracker = tracker
        self.featureFlagProvider = featureFlagProvider
        
        title = album.name
        numberOfNodes = album.count
        isLinkShared = album.isLinkShared
        
        if let coverNode = album.coverNode,
           let container = thumbnailUseCase.cachedThumbnailContainer(for: coverNode, type: .thumbnail) {
            thumbnailContainer = container
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
        guard !album.systemAlbum else { return }
        isSelected.toggle()
        
        tracker.trackAnalyticsEvent(with: album.makeAlbumSelectedEvent(
            selectionType: isSelected ? .multiadd : .multiremove))
    }
    
    @MainActor
    func monitorAlbumPhotos() async {
        guard featureFlagProvider.isFeatureFlagEnabled(for: .albumPhotoCache),
              album.type == .user else { return }
        
        for await albumPhotos in await monitorAlbumsUseCase.monitorUserAlbumPhotos(for: album) {
            numberOfNodes = albumPhotos.count
            
            guard shouldUseDefaultCover(photos: albumPhotos) else {
                await loadAlbumCoverIfNeeded(from: albumPhotos)
                continue
            }
            await setDefaultAlbumCover(albumPhotos)
        }
    }
    
    // MARK: Private
    
    @MainActor
    private func setDefaultAlbumCover(_ photos: [AlbumPhotoEntity]) async {
        guard let latestPhoto = photos.max(by: { lhs, rhs in
            if lhs.photo.modificationTime == rhs.photo.modificationTime {
                lhs.id < rhs.id
            } else {
                lhs.photo.modificationTime < rhs.photo.modificationTime
            }
        })?.photo else { return }
        
        await loadThumbnail(for: latestPhoto)
    }
    
    @MainActor
    private func loadThumbnail(for node: NodeEntity) async {
        guard let imageContainer = try? await thumbnailUseCase.loadThumbnailContainer(for: node, type: .thumbnail) else {
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
              let imageContainer = try? await thumbnailUseCase.loadThumbnailContainer(for: cover, type: .thumbnail),
              !thumbnailContainer.isEqual(imageContainer) else {
            return
        }
        thumbnailContainer = imageContainer
    }
}
