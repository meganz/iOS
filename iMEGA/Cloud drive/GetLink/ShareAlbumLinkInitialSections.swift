import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADomain
import MEGAL10n

struct ShareAlbumLinkInitialSections {
    private let album: AlbumEntity
    private let thumbnailUseCase: any ThumbnailUseCaseProtocol
    private let monitorUserAlbumPhotosUseCase: any MonitorUserAlbumPhotosUseCaseProtocol
    private let sensitiveDisplayPreferenceUseCase: any SensitiveDisplayPreferenceUseCaseProtocol
    private let albumCoverUseCase: any AlbumCoverUseCaseProtocol
    
    init(album: AlbumEntity,
         thumbnailUseCase: some ThumbnailUseCaseProtocol,
         monitorUserAlbumPhotosUseCase: some MonitorUserAlbumPhotosUseCaseProtocol,
         sensitiveDisplayPreferenceUseCase: some SensitiveDisplayPreferenceUseCaseProtocol,
         albumCoverUseCase: any AlbumCoverUseCaseProtocol) {
        self.album = album
        self.thumbnailUseCase = thumbnailUseCase
        self.monitorUserAlbumPhotosUseCase = monitorUserAlbumPhotosUseCase
        self.sensitiveDisplayPreferenceUseCase = sensitiveDisplayPreferenceUseCase
        self.albumCoverUseCase = albumCoverUseCase
    }
    
    @MainActor
    var initialLinkSectionViewModels: [GetLinkSectionViewModel] {
        [
            GetLinkSectionViewModel(sectionType: .info, cellViewModels: [
                GetLinkAlbumInfoCellViewModel(
                    album: album,
                    thumbnailUseCase: thumbnailUseCase,
                    monitorUserAlbumPhotosUseCase: monitorUserAlbumPhotosUseCase,
                    sensitiveDisplayPreferenceUseCase: sensitiveDisplayPreferenceUseCase,
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
