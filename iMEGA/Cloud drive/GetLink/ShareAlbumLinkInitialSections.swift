import MEGAData
import MEGADomain

struct ShareAlbumLinkInitialSections {
    private let album: AlbumEntity
    
    init(album: AlbumEntity) {
        self.album = album
    }
    
    var initialLinkSectionViewModels: [GetLinkSectionViewModel] {
        [
            GetLinkSectionViewModel(sectionType: .info, cellViewModels: [
                GetLinkAlbumInfoCellViewModel(album: album,
                                              thumbnailUseCase: ThumbnailUseCase(repository: ThumbnailRepository.newRepo))
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
