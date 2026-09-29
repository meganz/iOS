import Foundation
import MEGADomain
import MEGASwift
import MEGAUIComponent
import Search
import Testing
@testable import ViewedLinks
import ViewedLinksMock

@Suite("ViewedLinksSearchResultsProvider")
struct ViewedLinksSearchResultsProviderTests {
    @Test("a name query asks the use case for the name sort key")
    func nameQueryUsesNameSortKey() async throws {
        let useCase = MockViewedLinksUseCase()
        let sut = makeSUT(useCase: useCase)

        _ = await sut.search(queryRequest: query(key: .name, direction: .ascending), lastItemIndex: nil)

        #expect(useCase.lastSortKey == .name)
        #expect(useCase.lastAscending == true)
    }

    @Test("every other sort key collapses to last accessed")
    func otherSortKeysCollapseToLastAccessed() async throws {
        let keys: [MEGAUIComponent.SortOrder.Key] = [.favourite, .label, .dateAdded, .lastModified, .size, .shareCreated, .linkCreated]

        for key in keys {
            let useCase = MockViewedLinksUseCase()
            let sut = makeSUT(useCase: useCase)

            _ = await sut.search(queryRequest: query(key: key, direction: .descending), lastItemIndex: nil)

            #expect(useCase.lastSortKey == .lastAccessed)
            #expect(useCase.lastAscending == false)
        }
    }

    @Test("the initial query sorts by name ascending")
    func initialQuerySortsByNameAscending() async throws {
        let useCase = MockViewedLinksUseCase()
        let sut = makeSUT(useCase: useCase)

        _ = await sut.search(queryRequest: .initial, lastItemIndex: nil)

        #expect(useCase.lastSortKey == .name)
        #expect(useCase.lastAscending == true)
    }

    @Test("a refresh failure returns nil so the screen shows its empty state")
    func refreshFailureReturnsNil() async throws {
        let useCase = MockViewedLinksUseCase(errorToThrow: .storeOperationFailed)
        let sut = makeSUT(useCase: useCase)

        let results = try await sut.refreshedSearchResults(queryRequest: .initial)

        #expect(results == nil)
    }

    @Test("a cancelled refresh rethrows so the rows stay on screen")
    func cancelledRefreshRethrows() async throws {
        let useCase = MockViewedLinksUseCase(errorToThrow: .cancelled)
        let sut = makeSUT(useCase: useCase)

        await #expect(throws: CancellationError.self) {
            try await sut.refreshedSearchResults(queryRequest: .initial)
        }
    }

    @Test("a search failure returns an empty list rather than nil")
    func searchFailureReturnsEmptyList() async throws {
        let useCase = MockViewedLinksUseCase(errorToThrow: .storeOperationFailed)
        let sut = makeSUT(useCase: useCase)

        let results = try #require(await sut.search(queryRequest: .initial, lastItemIndex: nil))

        #expect(results.results.isEmpty)
    }

    @Test("a paging request returns nil without reading the store")
    func pagingRequestSkipsTheStore() async throws {
        let useCase = MockViewedLinksUseCase(viewedLinksResult: [try makeLink()])
        let sut = makeSUT(useCase: useCase)

        let results = await sut.search(queryRequest: .initial, lastItemIndex: 10)

        #expect(results == nil)
        #expect(useCase.viewedLinksCallCount == 0)
    }

    @Test("a search maps every link and carries no chips")
    func searchMapsEveryLink() async throws {
        let links = [try makeLink(handle: 1), try makeLink(handle: 2)]
        let sut = makeSUT(useCase: MockViewedLinksUseCase(viewedLinksResult: links))

        let results = try #require(await sut.search(queryRequest: .initial, lastItemIndex: nil))

        #expect(results.results.map(\.id) == [1, 2])
        #expect(results.availableChips.isEmpty)
        #expect(results.appliedChips.isEmpty)
    }

    @Test("a completed search fills the cache the view model reads")
    func completedSearchFillsTheCache() async throws {
        let links = [try makeLink(handle: 1), try makeLink(handle: 2), try makeLink(handle: 3)]
        let sut = makeSUT(useCase: MockViewedLinksUseCase(viewedLinksResult: links))

        _ = await sut.search(queryRequest: .initial, lastItemIndex: nil)

        #expect(sut.currentResultIds() == [1, 2, 3])
        #expect(sut.link(for: 2)?.handle == 2)
        #expect(sut.link(for: 99) == nil)
        #expect(sut.links(for: [1, 3]).map(\.handle) == [1, 3])
    }

    @Test("the cache is empty before any query runs")
    func cacheIsEmptyBeforeAnyQuery() {
        let sut = makeSUT(useCase: MockViewedLinksUseCase())

        #expect(sut.currentResultIds().isEmpty)
        #expect(sut.links(for: [1]).isEmpty)
    }

    @Test("every store change becomes a generic update signal")
    func storeChangesBecomeGenericSignals() async throws {
        let useCase = MockViewedLinksUseCase()
        useCase.changesSignalSequenceResult = AsyncStream<Void> { continuation in
            continuation.yield()
            continuation.yield()
            continuation.finish()
        }.eraseToAnyAsyncSequence()
        let sut = makeSUT(useCase: useCase)

        var signals: [SearchResultUpdateSignal] = []
        for await signal in sut.searchResultUpdateSignalSequence() {
            signals.append(signal)
        }

        #expect(signals == [.generic, .generic])
    }

    // MARK: - Helpers

    private func makeSUT(useCase: MockViewedLinksUseCase) -> ViewedLinksSearchResultsProvider {
        ViewedLinksSearchResultsProvider(
            viewedLinksUseCase: useCase,
            mapper: ViewedLinkSearchResultMapper(thumbnailUseCase: MockViewedLinkThumbnailUseCase())
        )
    }

    private func query(key: MEGAUIComponent.SortOrder.Key, direction: MEGAUIComponent.SortOrder.SortDirection) -> SearchQuery {
        .userSupplied(
            SearchQueryEntity(
                query: "",
                sorting: MEGAUIComponent.SortOrder(key: key, direction: direction),
                mode: .home,
                isSearchActive: false,
                chips: []
            )
        )
    }

    private func makeLink(
        handle: HandleEntity = 1,
        name: String = "file.jpg",
        isFolder: Bool = false,
        hasThumbnail: Bool = false
    ) throws -> ViewedLinkEntity {
        let url = try #require(URL(string: "https://mega.nz/file/\(handle)#key"))
        return ViewedLinkEntity(
            handle: handle,
            linkURL: url,
            name: name,
            isFolder: isFolder,
            hasThumbnail: hasThumbnail,
            lastAccessed: Date(timeIntervalSince1970: 0)
        )
    }
}
