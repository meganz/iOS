import Foundation
import MEGAL10n
import UIKit

/// Development only implementation, will be moved to SearchMocks on next MR once
/// we have actual results provider using real SDK
public struct NonProductionTestResultsProvider: SearchResultsProviding {
    public var empty: Bool
    public init(empty: Bool = false) {
        self.empty = empty
    }

    public func search(queryRequest: SearchQuery, lastItemIndex: Int?) async throws -> SearchResultsEntity? {
        
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
        let id = TestChip(rawValue: chip.id)
        switch id {
        case .images: return SearchResult.imageResults
        case .docs:   return SearchResult.docsResults
        case .audio:  return SearchResult.audioResults
        case .video:  return SearchResult.videoResults
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
        case docs
        case audio
        case video
        
        var title: String {
            switch self {
                
            case .images:
                return Strings.Localizable.Home.Search.Filter.images
            case .docs:
                return Strings.Localizable.Home.Search.Filter.docs
            case .audio:
                return Strings.Localizable.Home.Search.Filter.audio
            case .video:
                return Strings.Localizable.Home.Search.Filter.video
            }
        }
    }
    
    var allChips: [SearchChipEntity] {
        TestChip.allCases.map {
            .init(id: $0.rawValue, title: $0.title)
        }
    }
    
    private func chipsFor(query: SearchQuery) -> [SearchChipEntity] {
        query.chips
    }
}

fileprivate extension SearchQuery {
    static let empty: Self = .userSupplied(.init(query: "", sorting: .automatic, mode: .home, chips: []))
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
            description: "Parent folder",
            type: .node,
            properties: [],
            thumbnailImageData: { image }
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
}
