import MEGADomain
import MEGAL10n
import MEGAPresentation
import MEGASDKRepo

struct ShareAlbumLinkInitialSections {
    private let album: AlbumEntity
    private let thumbnailUseCase: any ThumbnailUseCaseProtocol
    private let monitorAlbumsUseCase: any MonitorAlbumsUseCaseProtocol
    private let contentConsumptionUserAttributeUseCase: any ContentConsumptionUserAttributeUseCaseProtocol
    private let albumCoverUseCase: any AlbumCoverUseCaseProtocol
    
    init(album: AlbumEntity,
         thumbnailUseCase: some ThumbnailUseCaseProtocol,
         monitorAlbumsUseCase: some MonitorAlbumsUseCaseProtocol,
         contentConsumptionUserAttributeUseCase: some ContentConsumptionUserAttributeUseCaseProtocol,
         albumCoverUseCase: any AlbumCoverUseCaseProtocol) {
        self.album = album
        self.thumbnailUseCase = thumbnailUseCase
        self.monitorAlbumsUseCase = monitorAlbumsUseCase
        self.contentConsumptionUserAttributeUseCase = contentConsumptionUserAttributeUseCase
        self.albumCoverUseCase = albumCoverUseCase
    }
    
    var initialLinkSectionViewModels: [GetLinkSectionViewModel] {
        [
            GetLinkSectionViewModel(sectionType: .info, cellViewModels: [
                GetLinkAlbumInfoCellViewModel(
                    album: album,
                    thumbnailUseCase: thumbnailUseCase,
                    monitorAlbumsUseCase: monitorAlbumsUseCase,
                    contentConsumptionUserAttributeUseCase: contentConsumptionUserAttributeUseCase,
                    albumCoverUseCase: albumCoverUseCase
                )
            ]),
            GetLinkSectionViewModel(sectionType: .decryptKeySeparate, cellViewModels: [
                GetLinkSwitchOptionCellViewModel(type: .decryptKeySeparate,
                                                 configuration: GetLinkSwitchCellViewConfiguration(title: Strings.Localizable.sendDecryptionKeySeparately))
            ]),
            GetLinkSectionViewModel(sectionType: .link, cellViewModels: [
                GetLinkStringCellViewModel(link: "")
            ])
        ]
    }
}
