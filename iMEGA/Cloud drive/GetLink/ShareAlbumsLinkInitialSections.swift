import Foundation
import MEGADomain
import MEGAPresentation
import MEGASDKRepo

struct ShareAlbumsLinkInitialSections {
    private let albums: [AlbumEntity]
    private let thumbnailUseCase: any ThumbnailUseCaseProtocol
    private let monitorUserAlbumPhotosUseCase: any MonitorUserAlbumPhotosUseCaseProtocol
    private let contentConsumptionUserAttributeUseCase: any ContentConsumptionUserAttributeUseCaseProtocol
    private let albumCoverUseCase: any AlbumCoverUseCaseProtocol
    
    init(albums: [AlbumEntity],
         thumbnailUseCase: some ThumbnailUseCaseProtocol,
         monitorUserAlbumPhotosUseCase: any MonitorUserAlbumPhotosUseCaseProtocol,
         contentConsumptionUserAttributeUseCase: some ContentConsumptionUserAttributeUseCaseProtocol,
         albumCoverUseCase: any AlbumCoverUseCaseProtocol) {
        self.albums = albums
        self.thumbnailUseCase = thumbnailUseCase
        self.monitorUserAlbumPhotosUseCase = monitorUserAlbumPhotosUseCase
        self.contentConsumptionUserAttributeUseCase = contentConsumptionUserAttributeUseCase
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
                    contentConsumptionUserAttributeUseCase: contentConsumptionUserAttributeUseCase,
                    albumCoverUseCase: albumCoverUseCase
                ),
                GetLinkStringCellViewModel(link: "")
            ], itemHandle: $0.id)
        }
    }
}
