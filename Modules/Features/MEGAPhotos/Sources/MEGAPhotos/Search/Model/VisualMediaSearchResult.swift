import ContentLibraries
import MEGAL10n

struct VisualMediaSearchResults: Equatable {
    enum Section {
        case albums
        case photos
    }
    enum Item {
        case album(AlbumCellViewModel)
        case photo(PhotoSearchResultItemViewModel)
    }
    struct SectionContent: Equatable {
        let section: Section
        let items: [Item]
    }
    
    let sectionContents: [SectionContent]
    
    init(sectionContents: [SectionContent]) {
        self.sectionContents = sectionContents
    }
}

extension VisualMediaSearchResults.Item: Hashable {
    func hash(into hasher: inout Hasher) {
        switch self {
        case .album(let item):
            hasher.combine(item.id.hashValue)
        case .photo(let item):
            hasher.combine(item.id.hashValue)
        }
    }
}

extension VisualMediaSearchResults.Section {
    var title: String {
        switch self {
        case .albums:
            Strings.Localizable.CameraUploads.Albums.title
        case .photos:
            Strings.Localizable.Photos.SearchResults.Media.Section.title
        }
    }
}
