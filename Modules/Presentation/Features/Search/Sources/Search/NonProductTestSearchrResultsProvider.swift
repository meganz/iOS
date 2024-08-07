import Foundation
import MEGAL10n
import UIKit

/// Development only implementation, will be moved to SearchMocks on next MR once
/// we have actual results provider using real SDK
public struct NonProductionTestResultsProvider: SearchResultsProviding {
    public func listenToSpecificResultUpdates() async {}
    
    public func refreshedSearchResults(queryRequest: SearchQuery) async throws -> SearchResultsEntity? {
        nil
    }
    
    public func currentResultIds() -> [ResultId] {
        []
    }
    
    public var empty: Bool
    public init(empty: Bool = false) {
        self.empty = empty
    }

    public func search(queryRequest: SearchQuery, lastItemIndex: Int?) async -> SearchResultsEntity? {
        
        if
            queryRequest == .initial ||
            queryRequest == .empty
        {
            return all
        }
        
        let searchString = queryRequest.query
        let chips = queryRequest.chips
        
        let results = filter(using: searchString, chip: chips.first)
        
        return .init(
            results: empty ? [] : results,
            availableChips: allChips,
            appliedChips: chipsFor(query: queryRequest)
        )
    }

    func filter(using query: String, chip: SearchChipEntity?) -> [SearchResult] {
        guard let chip else {
            return allResults.filter { $0.title.contains(query) }
        }
        
        let itemsToFilter = itemsToFilter(for: chip)
        
        if query == "" {
            return itemsToFilter
        }
        
        return itemsToFilter.filter { $0.title.contains(query) }
    }
    
    func itemsToFilter(for chip: SearchChipEntity) -> [SearchResult] {
        // Update this test
        let id = TestChip(rawValue: 0)
        switch id {
        case .images: return SearchResult.imageResults
        case .folders: return SearchResult.folderResults
        case .audio: return SearchResult.audioResults
        case .video: return SearchResult.videoResults
        case .pdf: return SearchResult.pdfResults
        case .docs: return SearchResult.docsResults
        case .presentations: return SearchResult.presentationResults
        case .archives: return SearchResult.archiveResults
        default:
            fatalError("unhandled scenario in this mock")
        }
    }
    
    var all: SearchResultsEntity {
        .init(
            results: allResults,
            availableChips: allChips,
            appliedChips: []
        )
    }
    
    var allResults: [SearchResult] {
        let all = SearchResult.imageResults +
        SearchResult.audioResults +
        SearchResult.docsResults +
        SearchResult.videoResults
        return all.sorted { $0.id > $1.id }
    }
    
    enum TestChip: Int, CaseIterable {
        case images
        case folders
        case audio
        case video
        case pdf
        case docs
        case presentations
        case archives

        var title: String {
            switch self {
            case .images:
                return Strings.Localizable.Home.Search.Filter.images
            case .folders:
                return Strings.Localizable.Home.Search.Filter.folders
            case .audio:
                return Strings.Localizable.Home.Search.Filter.audio
            case .video:
                return Strings.Localizable.Home.Search.Filter.video
            case .pdf:
                return Strings.Localizable.Home.Search.Filter.pdfs
            case .docs:
                return Strings.Localizable.Home.Search.Filter.docs
            case .presentations:
                return Strings.Localizable.Home.Search.Filter.presentations
            case .archives:
                return Strings.Localizable.Home.Search.Filter.archives
            }
        }
        
        var chipType: SearchChipEntity.ChipType {
            switch self {
            case .images:
                .nodeFormat(.photo)
            case .folders:
                .nodeType(.folder)
            case .audio:
                .nodeFormat(.audio)
            case .video:
                .nodeFormat(.video)
            case .pdf:
                .nodeFormat(.pdf)
            case .docs:
                .nodeFormat(.allDocs)
            case .presentations:
                .nodeFormat(.presentation)
            case .archives:
                .nodeFormat(.archive)
            }
        }
    }
    
    var allChips: [SearchChipEntity] {
        TestChip.allCases.map {
            .init(type: $0.chipType, title: $0.title)
        }
    }

    private func chipsFor(query: SearchQuery) -> [SearchChipEntity] {
        query.chips
    }
}

fileprivate extension SearchQuery {
    static let empty: Self = .userSupplied(
        .init(query: "", sorting: .nameAscending, mode: .home, isSearchActive: false, chips: [])
    )
}

fileprivate extension SearchResult {
    private static func image(_ name: String) -> Data {
        UIImage(systemName: name)!.withRenderingMode(.alwaysTemplate).pngData()!
    }
    private static func test(
        idx: UInt64,
        prefix: String,
        image: Data,
        thumbnailDisplayMode: ResultCellLayout.ThumbnailMode = .vertical,
        backgroundDisplayMode: VerticalBackgroundViewMode = .preview
    ) -> SearchResult {
        .init(
            id: idx,
            thumbnailDisplayMode: thumbnailDisplayMode,
            backgroundDisplayMode: backgroundDisplayMode,
            title: "\(prefix) \(idx)",
            isSensitive: false,
            hasThumbnail: false,
            description: { _ in "Parent folder" },
            type: .node,
            properties: [],
            thumbnailImageData: { image }, 
            swipeActions: { _ in [] }
        )
    }
    
    static var imageResults: [Self] {
        [
            test(idx: 1, prefix: "Image", image: image("photo"), thumbnailDisplayMode: .vertical, backgroundDisplayMode: .preview),
            test(idx: 3, prefix: "Image", image: image("photo"), thumbnailDisplayMode: .vertical, backgroundDisplayMode: .icon),
            test(idx: 10, prefix: "Image", image: image("photo"), thumbnailDisplayMode: .vertical, backgroundDisplayMode: .icon)
        ]
    }
    
    static var docsResults: [Self] {
        [
            test(idx: 4, prefix: "Doc", image: image("doc.richtext")),
            test(idx: 14, prefix: "Doc", image: image("doc.richtext")),
            test(idx: 44, prefix: "Doc", image: image("doc.richtext"))
        ]
    }
    
    static var audioResults: [Self] {
        [
            test(idx: 2, prefix: "Audio", image: image("music.note")),
            test(idx: 5, prefix: "Audio", image: image("music.note")),
            test(idx: 12, prefix: "Audio", image: image("music.note"))
        ]
    }
    
    static var videoResults: [Self] {
        [
            test(idx: 7, prefix: "Video", image: image("video")),
            test(idx: 17, prefix: "Video", image: image("video")),
            test(idx: 77, prefix: "Video", image: image("video"))
        ]
    }

    static var folderResults: [Self] {
        [
            test(idx: 100, prefix: "Folder", image: image("folder")),
            test(idx: 101, prefix: "Folder", image: image("folder")),
            test(idx: 102, prefix: "Folder", image: image("folder"))
        ]
    }

    static var pdfResults: [Self] {
        [
            test(idx: 103, prefix: "PDF", image: image("doc.on.doc.fill")),
            test(idx: 104, prefix: "PDF", image: image("doc.on.doc.fill")),
            test(idx: 105, prefix: "PDF", image: image("doc.on.doc.fill"))
        ]
    }

    static var presentationResults: [Self] {
        [
            test(idx: 104, prefix: "Presentation", image: image("videoprojector")),
            test(idx: 105, prefix: "Presentation", image: image("videoprojector")),
            test(idx: 106, prefix: "Presentation", image: image("videoprojector"))
        ]
    }

    static var archiveResults: [Self] {
        [
            test(idx: 107, prefix: "Archive", image: image("archivebox")),
            test(idx: 108, prefix: "Archive", image: image("archivebox")),
            test(idx: 109, prefix: "Archive", image: image("archivebox"))
        ]
    }
}
