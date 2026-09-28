import Foundation
import MEGASwift
import Search
@testable import ViewedLinks

/// The Search facing half returns nothing, because the view model only reads the lookup half.
struct MockViewedLinksResultsProvider: ViewedLinksResultsProviding {
    private let storedLinks: [ViewedLinkEntity]

    init(links: [ViewedLinkEntity] = []) {
        storedLinks = links
    }

    func refreshedSearchResults(queryRequest: SearchQuery) async throws -> SearchResultsEntity? {
        nil
    }

    func search(queryRequest: SearchQuery, lastItemIndex: Int?) async -> SearchResultsEntity? {
        nil
    }

    func currentResultIds() -> [ResultId] {
        storedLinks.map(\.handle)
    }

    func searchResultUpdateSignalSequence() -> AnyAsyncSequence<SearchResultUpdateSignal> {
        AsyncStream<SearchResultUpdateSignal> { $0.finish() }.eraseToAnyAsyncSequence()
    }

    func link(for id: ResultId) -> ViewedLinkEntity? {
        storedLinks.first { $0.handle == id }
    }

    func links(for ids: Set<ResultId>) -> [ViewedLinkEntity] {
        storedLinks.filter { ids.contains($0.handle) }
    }
}
