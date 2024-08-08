import Foundation
import MEGADomain
import MEGAL10n
import MEGAPresentation
import MEGASwift

enum GetLinkInfoCellAction: ActionType {
    case onViewReady
    case cancelTasks
}

final class GetLinkAlbumInfoCellViewModel: ViewModelType, GetLinkCellViewModelType {
    enum Command: CommandType, Equatable {
        case setThumbnail(path: String)
        case setPlaceholderThumbnail
        case setLabels(title: String, subtitle: String)
    }
    
    var invokeCommand: ((Command) -> Void)?
    let type: GetLinkCellType = .info
    
    private let album: AlbumEntity
    private let thumbnailUseCase: any ThumbnailUseCaseProtocol
    private let monitorAlbumsUseCase: any MonitorAlbumsUseCaseProtocol
    private let contentConsumptionUserAttributeUseCase: any ContentConsumptionUserAttributeUseCaseProtocol
    private let albumCoverUseCase: any AlbumCoverUseCaseProtocol
    private let featureFlagProvider: any FeatureFlagProviderProtocol
    
    private(set) var loadingTask: Task<Void, Never>? {
        didSet { oldValue?.cancel() }
    }
    
    init(album: AlbumEntity,
         thumbnailUseCase: some ThumbnailUseCaseProtocol,
         monitorAlbumsUseCase: some MonitorAlbumsUseCaseProtocol,
         contentConsumptionUserAttributeUseCase: any ContentConsumptionUserAttributeUseCaseProtocol,
         albumCoverUseCase: some AlbumCoverUseCaseProtocol,
         featureFlagProvider: some FeatureFlagProviderProtocol = DIContainer.featureFlagProvider) {
        self.album = album
        self.thumbnailUseCase = thumbnailUseCase
        self.monitorAlbumsUseCase = monitorAlbumsUseCase
        self.contentConsumptionUserAttributeUseCase = contentConsumptionUserAttributeUseCase
        self.albumCoverUseCase = albumCoverUseCase
        self.featureFlagProvider = featureFlagProvider
    }
    
    deinit {
        cancelTasks()
    }
    
    func dispatch(_ action: GetLinkInfoCellAction) {
        switch action {
        case .onViewReady:
            if featureFlagProvider.isFeatureFlagEnabled(for: .albumPhotoCache) {
                loadAlbumPhotos()
            } else {
                invokeCommand?(.setLabels(title: album.name,
                                          subtitle: Strings.Localizable.General.Format.Count.items(album.count)))
                loadThumbnail()
            }
        case .cancelTasks:
            cancelTasks()
        }
    }
    
    private func loadThumbnail() {
        guard let coverNode = album.coverNode else {
            invokeCommand?(.setPlaceholderThumbnail)
            return
        }
        loadingTask = Task { @MainActor [weak self] in
            guard let self else { return }
            await loadThumbnail(for: coverNode)
        }
    }
    
    @MainActor
    private func loadThumbnail(for node: NodeEntity) async {
        do {
            let thumbnail = try await thumbnailUseCase.loadThumbnail(for: node, type: .thumbnail)
            guard !Task.isCancelled else { return }
            invokeCommand?(.setThumbnail(path: thumbnail.url.path))
        } catch {
            MEGALogError("Error loading album cover thumbnail: \(error.localizedDescription)")
            invokeCommand?(.setPlaceholderThumbnail)
        }
    }
    
    private func loadAlbumPhotos() {
        loadingTask = Task { @MainActor [weak self] in
            guard let albumPhotoAsyncSequence = await self?.albumPhotoAsyncSequence() else { return }
            
            for await photos in albumPhotoAsyncSequence {
                self?.updateLabels(photoCount: photos.count)
                await self?.albumCover(for: photos)
            }
        }
    }
    
    @MainActor
    private func albumPhotoAsyncSequence() async -> AnyAsyncSequence<[AlbumPhotoEntity]> {
        let excludeSensitives = await excludeSensitives()
        return await monitorAlbumsUseCase.monitorUserAlbumPhotos(
            for: album, excludeSensitives: excludeSensitives, includeSensitiveInherited: false)
    }
    
    @MainActor
    private func excludeSensitives() async -> Bool {
        if featureFlagProvider.isFeatureFlagEnabled(for: .hiddenNodes) {
            await !contentConsumptionUserAttributeUseCase.fetchSensitiveAttribute().showHiddenNodes
        } else {
            false
        }
    }
    
    @MainActor
    private func updateLabels(photoCount: Int) {
        invokeCommand?(.setLabels(title: album.name,
                                  subtitle: Strings.Localizable.General.Format.Count.items(photoCount)))
    }
    
    @MainActor
    private func albumCover(for photos: [AlbumPhotoEntity]) async {
        if let albumCover = await albumCoverUseCase.albumCover(for: album, photos: photos) {
            await loadThumbnail(for: albumCover)
        } else {
            invokeCommand?(.setPlaceholderThumbnail)
        }
    }
    
    private func cancelTasks() {
        loadingTask = nil
    }
}
