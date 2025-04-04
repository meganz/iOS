import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADomain
import MEGAL10n

struct ShareVideoPlaylistLinkInitialSections {
    private let videoPlaylist: VideoPlaylistEntity
    private let thumbnailUseCase: any ThumbnailUseCaseProtocol
    
    init(videoPlaylist: VideoPlaylistEntity,
         thumbnailUseCase: some ThumbnailUseCaseProtocol) {
        self.videoPlaylist = videoPlaylist
        self.thumbnailUseCase = thumbnailUseCase
    }
    
    @MainActor
    var initialLinkSectionViewModels: [GetLinkSectionViewModel] {
        [
            GetLinkSectionViewModel(sectionType: .info, cellViewModels: [
                // CC-7728
            ]),
            GetLinkSectionViewModel(sectionType: .linkAccessInfo, cellViewModels: [
                GetLinkAccessInfoCellViewModel(title: Strings.Localizable.SharedItems.Link.accessInfo(1))
            ]),
            GetLinkSectionViewModel(sectionType: .decryptKeySeparate, cellViewModels: [
                GetLinkSwitchOptionCellViewModel(
                    type: .decryptKeySeparate,
                    configuration: GetLinkSwitchCellViewConfiguration(title: Strings.Localizable.sendDecryptionKeySeparately)
                )
            ]),
            GetLinkSectionViewModel(sectionType: .link, cellViewModels: [
                GetLinkStringCellViewModel(link: "")
            ])
        ]
    }
}
