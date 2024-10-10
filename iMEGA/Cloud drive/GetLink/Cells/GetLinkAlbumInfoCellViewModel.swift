import Foundation
import MEGADomain
import MEGAL10n
import MEGAPresentation
import MEGASwift

enum GetLinkInfoCellAction: ActionType {
    case onViewReady
    case cancelTasks
}

@MainActor
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
    private let monitorUserAlbumPhotosUseCase: any MonitorUserAlbumPhotosUseCaseProtocol
    private let sensitiveDisplayPreferenceUseCase: any SensitiveDisplayPreferenceUseCaseProtocol
    private let albumCoverUseCase: any AlbumCoverUseCaseProtocol
    private let albumRemoteFeatureFlagProvider: any AlbumRemoteFeatureFlagProviderProtocol
    
    private(set) var loadingTask: Task<Void, Never>? {
        didSet { oldValue?.cancel() }
    }
    
    init(album: AlbumEntity,
         thumbnailUseCase: some ThumbnailUseCaseProtocol,
         monitorUserAlbumPhotosUseCase: some MonitorUserAlbumPhotosUseCaseProtocol,
         sensitiveDisplayPreferenceUseCase: some SensitiveDisplayPreferenceUseCaseProtocol,
         albumCoverUseCase: some AlbumCoverUseCaseProtocol,
         albumRemoteFeatureFlagProvider: some AlbumRemoteFeatureFlagProviderProtocol = AlbumRemoteFeatureFlagProvider()) {
        self.album = album
        self.thumbnailUseCase = thumbnailUseCase
        self.monitorUserAlbumPhotosUseCase = monitorUserAlbumPhotosUseCase
        self.sensitiveDisplayPreferenceUseCase = sensitiveDisplayPreferenceUseCase
        self.albumCoverUseCase = albumCoverUseCase
        self.albumRemoteFeatureFlagProvider = albumRemoteFeatureFlagProvider
    }
    
    deinit {
        loadingTask = nil
    }
    
    func dispatch(_ action: GetLinkInfoCellAction) {
        switch action {
        case .onViewReady:
            onViewReady()
        case .cancelTasks:
            loadingTask = nil
        }
    }
    
    private func onViewReady() {
        loadingTask = Task {
            if await albumRemoteFeatureFlagProvider.isPerformanceImprovementsEnabled() {
                await loadAlbumPhotos()
            } else {
                invokeCommand?(.setLabels(title: album.name,
                                          subtitle: Strings.Localizable.General.Format.Count.items(album.count)))
                await loadThumbnail()
            }
        }
    }
    
    private func loadThumbnail() async {
        guard let coverNode = album.coverNode else {
            invokeCommand?(.setPlaceholderThumbnail)
            return
        }
        await loadThumbnail(for: coverNode)
    }
    
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
    
    private func loadAlbumPhotos() async {
        for await photos in await albumPhotoAsyncSequence() {
            updateLabels(photoCount: photos.count)
            await albumCover(for: photos)
        }
    }
    
    private func albumPhotoAsyncSequence() async -> AnyAsyncSequence<[AlbumPhotoEntity]> {
        let excludeSensitives = await sensitiveDisplayPreferenceUseCase.excludeSensitives()
        return await monitorUserAlbumPhotosUseCase.monitorUserAlbumPhotos(
            for: album, excludeSensitives: excludeSensitives)
    }
    
    private func updateLabels(photoCount: Int) {
        invokeCommand?(.setLabels(title: album.name,
                                  subtitle: Strings.Localizable.General.Format.Count.items(photoCount)))
    }
    
    private func albumCover(for photos: [AlbumPhotoEntity]) async {
        if let albumCover = await albumCoverUseCase.albumCover(for: album, photos: photos) {
            await loadThumbnail(for: albumCover)
        } else {
            invokeCommand?(.setPlaceholderThumbnail)
        }
    }
}
