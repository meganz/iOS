import Foundation
import MEGADomain
import MEGAPresentation
import MEGASDKRepo

struct ShareAlbumsLinkInitialSections {
    private let albums: [AlbumEntity]
    private let thumbnailUseCase: any ThumbnailUseCaseProtocol
    private let monitorAlbumsUseCase: any MonitorAlbumsUseCaseProtocol
    private let contentConsumptionUserAttributeUseCase: any ContentConsumptionUserAttributeUseCaseProtocol
    private let albumCoverUseCase: any AlbumCoverUseCaseProtocol
    
    init(albums: [AlbumEntity],
         thumbnailUseCase: some ThumbnailUseCaseProtocol,
         monitorAlbumsUseCase: any MonitorAlbumsUseCaseProtocol,
         contentConsumptionUserAttributeUseCase: some ContentConsumptionUserAttributeUseCaseProtocol,
         albumCoverUseCase: any AlbumCoverUseCaseProtocol) {
        self.albums = albums
        self.thumbnailUseCase = thumbnailUseCase
        self.monitorAlbumsUseCase = monitorAlbumsUseCase
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
                    monitorAlbumsUseCase: monitorAlbumsUseCase,
                    contentConsumptionUserAttributeUseCase: contentConsumptionUserAttributeUseCase,
                    albumCoverUseCase: albumCoverUseCase
                ),
                GetLinkStringCellViewModel(link: "")
            ], itemHandle: $0.id)
        }
    }
}
