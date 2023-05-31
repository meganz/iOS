import Foundation
import MEGADomain

struct ShareAlbumsLinkInitialSections {
    private let albums: [AlbumEntity]
    private let thumbnailUseCase: ThumbnailUseCaseProtocol
    
    init(albums: [AlbumEntity],
         thumbnailUseCase: ThumbnailUseCaseProtocol) {
        self.albums = albums
        self.thumbnailUseCase = thumbnailUseCase
    }
    
    var initialLinkSectionViewModels: [GetLinkSectionViewModel] {
        albums.map {
            GetLinkSectionViewModel(sectionType: .link, cellViewModels: [
                GetLinkAlbumInfoCellViewModel(album: $0,
                                              thumbnailUseCase: thumbnailUseCase),
                GetLinkStringCellViewModel(link: "")
            ], itemHandle: $0.id)
        }
    }
}
