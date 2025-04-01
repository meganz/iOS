import Foundation
import MEGAAppPresentation
import MEGADomain
import MEGASDKRepo

struct ShareAlbumsLinkInitialSections {
    private let albums: [AlbumEntity]
    private let thumbnailUseCase: any ThumbnailUseCaseProtocol
    private let monitorUserAlbumPhotosUseCase: any MonitorUserAlbumPhotosUseCaseProtocol
    private let sensitiveDisplayPreferenceUseCase: any SensitiveDisplayPreferenceUseCaseProtocol
    private let albumCoverUseCase: any AlbumCoverUseCaseProtocol
    
    init(albums: [AlbumEntity],
         thumbnailUseCase: some ThumbnailUseCaseProtocol,
         monitorUserAlbumPhotosUseCase: some MonitorUserAlbumPhotosUseCaseProtocol,
         sensitiveDisplayPreferenceUseCase: some SensitiveDisplayPreferenceUseCaseProtocol,
         albumCoverUseCase: some AlbumCoverUseCaseProtocol) {
        self.albums = albums
        self.thumbnailUseCase = thumbnailUseCase
        self.monitorUserAlbumPhotosUseCase = monitorUserAlbumPhotosUseCase
        self.sensitiveDisplayPreferenceUseCase = sensitiveDisplayPreferenceUseCase
        self.albumCoverUseCase = albumCoverUseCase
    }
    
    @MainActor
    var initialLinkSectionViewModels: [GetLinkSectionViewModel] {
        albums.map {
            GetLinkSectionViewModel(sectionType: .link, cellViewModels: [
                GetLinkAlbumInfoCellViewModel(
                    album: $0,
                    thumbnailUseCase: thumbnailUseCase,
                    monitorUserAlbumPhotosUseCase: monitorUserAlbumPhotosUseCase,
                    sensitiveDisplayPreferenceUseCase: sensitiveDisplayPreferenceUseCase,
                    albumCoverUseCase: albumCoverUseCase
                ),
                GetLinkStringCellViewModel(link: "")
            ], setIdentifier: $0.setIdentifier)
        }
    }
}
