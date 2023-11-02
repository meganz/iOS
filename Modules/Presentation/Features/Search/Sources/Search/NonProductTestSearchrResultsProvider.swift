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
    private static func thumbnailPreviewData() -> SearchResultThumbnailInfo {
        .init(
            id: "1",
            displayMode: .file,
            title: "File title",
            subtitle: "Info",
            iconIndicatorPath: nil,
            duration: "2:00",
            isVideoIconHidden: true,
            hasThumbnail: true,
            thumbnailImageData: { .init() },
            propertiesData: { [] },
            downloadVisibilityData: { false }
        )
    }
    static var imageResults: [Self] {
        [
            .init(id: 1, title: "Image 1", description: "Parent folder", properties: [], thumbnailImageData: { image("photo") }, type: .node, thumbnailPreviewInfo: thumbnailPreviewData()),
            .init(id: 3, title: "Image 2", description: "Parent folder", properties: [], thumbnailImageData: { image("photo") }, type: .node, thumbnailPreviewInfo: thumbnailPreviewData()),
            .init(id: 10, title: "Image 3", description: "Parent folder", properties: [], thumbnailImageData: { image("photo") }, type: .node, thumbnailPreviewInfo: thumbnailPreviewData())
        ]
    }
    
    static var docsResults: [Self] {
        [
            .init(id: 23, title: "Doc 1", description: "Parent folder", properties: [], thumbnailImageData: { image("doc.richtext") }, type: .node, thumbnailPreviewInfo: thumbnailPreviewData()),
            .init(id: 44, title: "Doc 2", description: "Parent folder", properties: [], thumbnailImageData: { image("doc.richtext") }, type: .node, thumbnailPreviewInfo: thumbnailPreviewData()),
            .init(id: 11, title: "Doc 3", description: "Parent folder", properties: [], thumbnailImageData: { image("doc.richtext") }, type: .node, thumbnailPreviewInfo: thumbnailPreviewData())
        ]
    }
    
    static var audioResults: [Self] {
        [
            .init(id: 2, title: "Audio 1", description: "Parent folder", properties: [], thumbnailImageData: { image("music.note") }, type: .node, thumbnailPreviewInfo: thumbnailPreviewData()),
            .init(id: 5, title: "Audio 2", description: "Parent folder", properties: [], thumbnailImageData: { image("music.note") }, type: .node, thumbnailPreviewInfo: thumbnailPreviewData()),
            .init(id: 12, title: "Audio 3", description: "Parent folder", properties: [], thumbnailImageData: { image("music.note") }, type: .node, thumbnailPreviewInfo: thumbnailPreviewData())
        ]
    }
    
    static var videoResults: [Self] {
        [
            .init(id: 7, title: "Video 1", description: "Parent folder", properties: [], thumbnailImageData: { image("video") }, type: .node, thumbnailPreviewInfo: thumbnailPreviewData()),
            .init(id: 17, title: "Video 2", description: "Parent folder", properties: [], thumbnailImageData: { image("video") }, type: .node, thumbnailPreviewInfo: thumbnailPreviewData()),
            .init(id: 77, title: "Video 3", description: "Parent folder", properties: [], thumbnailImageData: { image("video") }, type: .node, thumbnailPreviewInfo: thumbnailPreviewData())
        ]
    }
}
