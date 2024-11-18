import ContentLibraries
import MEGAL10n

struct VisualMediaSearchResult: Equatable {
    enum Section {
        case albums
        case photos
    }
    enum Item {
        case album(AlbumCellViewModel)
        case photo(PhotoSearchResultItemViewModel)
    }
    let content: [Section: [Item]]
    
    init(content: [Section: [Item]]) {
        self.content = content
    }
}

extension VisualMediaSearchResult.Item: Hashable {
    func hash(into hasher: inout Hasher) {
        switch self {
        case .album(let item):
            hasher.combine(item.id.hashValue)
        case .photo(let item):
            hasher.combine(item.id.hashValue)
        }
    }
}

extension VisualMediaSearchResult.Section {
    var title: String {
        switch self {
        case .albums:
            Strings.Localizable.CameraUploads.Albums.title
        case .photos:
            Strings.Localizable.Photos.SearchResults.Media.Section.title
        }
    }
}
