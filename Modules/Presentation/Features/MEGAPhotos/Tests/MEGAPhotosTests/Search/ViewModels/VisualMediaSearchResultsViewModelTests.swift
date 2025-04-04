import Combine
import ContentLibraries
import MEGAAppPresentation
import MEGAAppPresentationMock
import MEGADomain
import MEGADomainMock
import MEGAL10n
@testable import MEGAPhotos
import MEGASwift
import MEGATest
import Testing
import XCTest

final class VisualMediaSearchResultsViewModelTests: XCTestCase {
    
    @MainActor
    func testMonitorSearchResults_emptyNoHistoryItems_shouldSetViewModeToEmpty() {
        let visualMediaSearchHistoryUseCase = MockVisualMediaSearchHistoryUseCase(
            searchQueryHistoryEntries: [])
        let sut = makeSUT(visualMediaSearchHistoryUseCase: visualMediaSearchHistoryUseCase)
        
        let exp = expectation(description: "recently searched items view state")
        let subscription = viewStateUpdates(on: sut) {
            XCTAssertEqual($0, .empty(description: Strings.Localizable.Photos.SearchHistory.Empty.description))
            exp.fulfill()
        }
        
        trackTaskCancellation { await sut.monitorSearchResults() }
        
        wait(for: [exp], timeout: 0.2)
        subscription.cancel()
    }
    
    @MainActor
    func testMonitorSearchResults_historyQueryItemsFound_shouldSetViewModeToRecentSearchedItems() throws {
        let historyItems = try makeHistoryEntries()
        let visualMediaSearchHistoryUseCase = MockVisualMediaSearchHistoryUseCase(
            searchQueryHistoryEntries: historyItems)
        
        let sut = makeSUT(visualMediaSearchHistoryUseCase: visualMediaSearchHistoryUseCase)
        
        let expectedItems = historyItems.sortedByDateQueries()
        let exp = expectation(description: "recently searched items view state")
        let subscription = viewStateUpdates(on: sut) {
            switch $0 {
            case .recentlySearched(let items):
                XCTAssertEqual(items.map(\.query), expectedItems)
                exp.fulfill()
            default:
                XCTFail("Unexpected view state \($0)")
            }
            
        }
        
        trackTaskCancellation { await sut.monitorSearchResults() }
        
        wait(for: [exp], timeout: 0.2)
        subscription.cancel()
    }
    
    @MainActor
    func testMonitorSearchResult_searchUpdated_shouldShowEmptyThenLoadingWithSearchResultsWhenCompleted() async throws {
        let visualMediaSearchHistoryUseCase = MockVisualMediaSearchHistoryUseCase(
            searchQueryHistoryEntries: [])
        let monitorAlbumsUseCase = MockMonitorAlbumsUseCase(
            monitorSystemAlbumsSequence: SingleItemAsyncSequence<Result<[AlbumEntity], any Error>>(
                item: .success([])).eraseToAnyAsyncSequence(),
            monitorUserAlbumsSequence: SingleItemAsyncSequence<[AlbumEntity]>(
                item: []).eraseToAnyAsyncSequence()
        )
        let searchText = "fav"
        let monitorPhotosUseCase = MockMonitorPhotosUseCase(monitorPhotosAsyncSequence: SingleItemAsyncSequence<Result<[NodeEntity], any Error>>(
            item: .success([.init(name: "\(searchText) car", handle: 1, modificationTime: try "2024-11-12T08:00:00Z".date)])).eraseToAnyAsyncSequence())
        let sut = makeSUT(
            visualMediaSearchHistoryUseCase: visualMediaSearchHistoryUseCase,
            monitorAlbumsUseCase: monitorAlbumsUseCase,
            monitorPhotosUseCase: monitorPhotosUseCase)
        
        let emptyExp = expectation(description: "Empty Shown")
        let loadingExp = expectation(description: "loading shown")
        let searchResultsExp = expectation(description: "loading and search result shown")
        
        let subscription = viewStateUpdates(on: sut) {
            switch $0 {
            case .empty: emptyExp.fulfill()
            case .loading: loadingExp.fulfill()
            case .searchResults: searchResultsExp.fulfill()
            default: XCTFail("Unexpected view state \($0)")
            }
        }
        
        trackTaskCancellation { await sut.monitorSearchResults() }
        
        await fulfillment(of: [emptyExp], timeout: 0.2)
        
        sut.updateSearchText(searchText)
        
        await fulfillment(of: [loadingExp, searchResultsExp], timeout: 0.2)
        subscription.cancel()
    }
    
    @MainActor
    func testUpdateSearchResult_emptyRetrievedHistoryAfterFirstSearch_shouldShowHistoryItemWhenSearchCleared() async throws {
        let searchText = "fav"
        let userAlbum = AlbumEntity(id: 1, name: "Queenstown Favourite Photos", type: .user)
        let systemAlbum = AlbumEntity(id: 2, name: "Favourites", type: .favourite)
        let visualMediaSearchHistoryUseCase = MockVisualMediaSearchHistoryUseCase(
            searchQueryHistoryEntries: [])
        let monitorAlbumsUseCase = MockMonitorAlbumsUseCase(
            monitorSystemAlbumsSequence: SingleItemAsyncSequence<Result<[AlbumEntity], any Error>>(
                item: .success([systemAlbum])).eraseToAnyAsyncSequence(),
            monitorUserAlbumsSequence: SingleItemAsyncSequence(
                item: [userAlbum]).eraseToAnyAsyncSequence()
        )
        let excludeSensitive = true
        let sensitiveDisplayPreferenceUseCase = MockSensitiveDisplayPreferenceUseCase(excludeSensitives: excludeSensitive)
        let photo1 = NodeEntity(name: "\(searchText) car", handle: 1, modificationTime: try "2024-11-12T08:00:00Z".date)
        let photo2 = NodeEntity(name: "\(searchText) bag", handle: 2, modificationTime: try "2024-11-12T08:00:00Z".date)
        let photo3 = NodeEntity(name: "\(searchText) game", handle: 3, modificationTime: try "2024-11-11T22:05:04Z".date)
        let photo4 = NodeEntity(name: "\(searchText) movie", handle: 4, modificationTime: try "2024-11-09T08:00:00Z".date)
        let monitorPhotosUseCase = MockMonitorPhotosUseCase(monitorPhotosAsyncSequence: SingleItemAsyncSequence<Result<[NodeEntity], any Error>>(
            item: .success([photo1, photo2, photo3, photo4])).eraseToAnyAsyncSequence())
        let sut = makeSUT(
            visualMediaSearchHistoryUseCase: visualMediaSearchHistoryUseCase,
            monitorAlbumsUseCase: monitorAlbumsUseCase,
            sensitiveDisplayPreferenceUseCase: sensitiveDisplayPreferenceUseCase,
            monitorPhotosUseCase: monitorPhotosUseCase)
        
        let exp = expectation(description: "search results")
        let subscription = viewStateUpdates(on: sut) {
            XCTAssertEqual($0, .searchResults(
                .init(sectionContents: [
                    .init(section: .albums, items: [
                        .album(AlbumCellViewModel(album: systemAlbum, searchText: searchText)),
                        .album(AlbumCellViewModel(album: userAlbum, searchText: searchText))
                    ]),
                    .init(section: .photos, items: [
                        .photo(PhotoSearchResultItemViewModel(photo: photo2, searchText: searchText)),
                        .photo(PhotoSearchResultItemViewModel(photo: photo1, searchText: searchText)),
                        .photo(PhotoSearchResultItemViewModel(photo: photo3, searchText: searchText)),
                        .photo(PhotoSearchResultItemViewModel(photo: photo4, searchText: searchText))
                    ])
                ])
            ))
            exp.fulfill()
        }
        
        trackTaskCancellation { await sut.monitorSearchResults() }
        
        sut.updateSearchText("1")
        sut.updateSearchText("2")
        sut.updateSearchText(searchText)
       
        await fulfillment(of: [exp], timeout: 0.5)
        
        let monitorTypes = await monitorAlbumsUseCase.state.monitorTypes
        XCTAssertEqual(Set(monitorTypes),
                       Set([.systemAlbum(excludeSensitives: excludeSensitive),
                            .userAlbum(excludeSensitives: excludeSensitive)]))
        
        subscription.cancel()
    }
    
    @MainActor
    func testSaveSearch_searchTextNotEmpty_shouldAddItemToSearchHistory() async {
        let lastSearch = "queenstown trip"
        let visualMediaSearchHistoryUseCase = MockVisualMediaSearchHistoryUseCase()
        let sut = makeSUT(visualMediaSearchHistoryUseCase: visualMediaSearchHistoryUseCase)
        sut.updateSearchText(lastSearch)
        
        await sut.saveSearch()
        
        let invocations = await visualMediaSearchHistoryUseCase.invocations
        XCTAssertEqual(invocations.count, 1)
        if case .add(let entry) = invocations.last {
            XCTAssertEqual(entry.query, lastSearch)
        } else {
            XCTFail("Expected addSearchHistory invocation")
        }
    }
    
    @MainActor
    func testHandleNavigation_onAlbumSelection_shouldNavigateToAlbumContent() {
        let expectedAlbum = AlbumEntity(id: 6, type: .user)
        let router = MockPhotoSearchResultRouter()
        let photoAlbumContainerInteractionManager = PhotoAlbumContainerInteractionManager()
        let sut = makeSUT(
            photoAlbumContainerInteractionManager: photoAlbumContainerInteractionManager,
            photoSearchResultRouter: router)
        
        trackTaskCancellation { await sut.handleSelectedItemNavigation() }
        
        let exp = expectation(description: "did select album on router")
        let subscription = router.$selectedAlbum
            .dropFirst()
            .sink {
                XCTAssertEqual($0, expectedAlbum)
                exp.fulfill()
            }
        
        let tabSwitchExp = expectation(description: "switch to photo tab")
        let tabSwitchSubscription = photoAlbumContainerInteractionManager.pageSwitchPublisher
            .sink {
                XCTAssertEqual($0, .album)
                tabSwitchExp.fulfill()
            }
        
        sut.selectedVisualMediaResult = .init(
            selectedItem: .album(.init(album: expectedAlbum)),
            otherQueryItems: [])
        
        wait(for: [exp, tabSwitchExp], timeout: 0.5)
        [subscription, tabSwitchSubscription].forEach { $0.cancel() }
    }
    
    @MainActor
    func testHandleNavigation_onPhotoSelection_shouldNavigateToPhotosWithOtherPhotos() {
        let expectedPhoto = NodeEntity(handle: 1)
        let expectedOtherPhotos = [NodeEntity(handle: 4), NodeEntity(handle: 5)]
        let router = MockPhotoSearchResultRouter()
        let photoAlbumContainerInteractionManager = PhotoAlbumContainerInteractionManager()
        let sut = makeSUT(
            photoAlbumContainerInteractionManager: photoAlbumContainerInteractionManager,
            photoSearchResultRouter: router)
        
        trackTaskCancellation { await sut.handleSelectedItemNavigation() }
        
        let exp = expectation(description: "did select photo on router")
        let subscription = router.$selectedPhoto
            .dropFirst()
            .sink {
                XCTAssertEqual($0?.photo, expectedPhoto)
                XCTAssertEqual($0?.otherPhotos, expectedOtherPhotos)
                exp.fulfill()
            }
        
        let tabSwitchExp = expectation(description: "switch to photo tab")
        let tabSwitchSubscription = photoAlbumContainerInteractionManager.pageSwitchPublisher
            .sink {
                XCTAssertEqual($0, .timeline)
                tabSwitchExp.fulfill()
            }
        
        sut.selectedVisualMediaResult = .init(
            selectedItem: .photo(.init(photo: expectedPhoto)),
            otherQueryItems: expectedOtherPhotos.map { .photo(.init(photo: $0)) })
        
        wait(for: [exp, tabSwitchExp], timeout: 0.5)
        [subscription, tabSwitchSubscription].forEach { $0.cancel() }
    }
    
    @MainActor
    private func makeSUT(
        photoAlbumContainerInteractionManager: PhotoAlbumContainerInteractionManager = PhotoAlbumContainerInteractionManager(),
        visualMediaSearchHistoryUseCase: some VisualMediaSearchHistoryUseCaseProtocol = MockVisualMediaSearchHistoryUseCase(),
        monitorAlbumsUseCase: some MonitorAlbumsUseCaseProtocol = MockMonitorAlbumsUseCase(),
        thumbnailLoader: some ThumbnailLoaderProtocol = MockThumbnailLoader(),
        monitorUserAlbumPhotosUseCase: some MonitorUserAlbumPhotosUseCaseProtocol = MockMonitorUserAlbumPhotosUseCase(),
        nodeUseCase: some NodeUseCaseProtocol = MockNodeUseCase(),
        sensitiveNodeUseCase: some SensitiveNodeUseCaseProtocol = MockSensitiveNodeUseCase(),
        sensitiveDisplayPreferenceUseCase: some SensitiveDisplayPreferenceUseCaseProtocol = MockSensitiveDisplayPreferenceUseCase(),
        albumCoverUseCase: some AlbumCoverUseCaseProtocol = MockAlbumCoverUseCase(),
        monitorPhotosUseCase: some MonitorPhotosUseCaseProtocol = MockMonitorPhotosUseCase(),
        photoSearchResultRouter: some PhotoSearchResultRouterProtocol = MockPhotoSearchResultRouter(),
        contentLibrariesConfiguration: ContentLibraries.Configuration = .init(
            sensitiveNodeUseCase: MockSensitiveNodeUseCase(),
            nodeUseCase: MockNodeUseCase(),
            isAlbumPerformanceImprovementsEnabled: { true }),
        searchDebounceTime: DispatchQueue.SchedulerTimeType.Stride = .milliseconds(150),
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> VisualMediaSearchResultsViewModel {
        let sut = VisualMediaSearchResultsViewModel(
            photoAlbumContainerInteractionManager: photoAlbumContainerInteractionManager,
            visualMediaSearchHistoryUseCase: visualMediaSearchHistoryUseCase,
            monitorAlbumsUseCase: monitorAlbumsUseCase,
            thumbnailLoader: thumbnailLoader,
            monitorUserAlbumPhotosUseCase: monitorUserAlbumPhotosUseCase,
            nodeUseCase: nodeUseCase,
            sensitiveNodeUseCase: sensitiveNodeUseCase,
            sensitiveDisplayPreferenceUseCase: sensitiveDisplayPreferenceUseCase,
            albumCoverUseCase: albumCoverUseCase,
            monitorPhotosUseCase: monitorPhotosUseCase,
            photoSearchResultRouter: photoSearchResultRouter,
            contentLibrariesConfiguration: contentLibrariesConfiguration,
            searchDebounceTime: searchDebounceTime)
        trackForMemoryLeaks(on: sut, timeoutNanoseconds: 1_000_000_000, file: file, line: line)
        return sut
    }
    
    @MainActor
    private func viewStateUpdates(on sut: VisualMediaSearchResultsViewModel, action: @escaping (VisualMediaSearchResultsViewModel.ViewState) -> Void) -> AnyCancellable {
        sut.$viewState
            .dropFirst()
            .sink(receiveValue: action)
    }
    
    private func makeHistoryEntries() throws -> [SearchTextHistoryEntryEntity] {
        [SearchTextHistoryEntryEntity(query: "1", searchDate: try "2024-01-01T22:00:00Z".date),
         SearchTextHistoryEntryEntity(query: "2", searchDate: try "2024-02-01T22:00:00Z".date),
         SearchTextHistoryEntryEntity(query: "3", searchDate: try "2024-03-01T22:00:00Z".date),
         SearchTextHistoryEntryEntity(query: "4", searchDate: try "2024-04-01T22:00:00Z".date),
         SearchTextHistoryEntryEntity(query: "5", searchDate: try "2024-05-01T22:00:00Z".date),
         SearchTextHistoryEntryEntity(query: "6", searchDate: try "2024-06-01T22:00:00Z".date)]
    }
    
    private func latestSearchQueries(from items: [SearchTextHistoryEntryEntity], lastSearch: String) -> [String] {
        var expectedItems = Array(items.sortedByDateQueries().prefix(5))
        expectedItems.insert(lastSearch, at: 0)
        return expectedItems
    }
}

private extension Sequence where Element == SearchTextHistoryEntryEntity {
    func sortedByDateQueries() -> [String] {
        sorted(by: { $0.searchDate > $1.searchDate }).map(\.query)
    }
}

private extension PhotoSearchResultItemViewModel {
    convenience init(
        photo: NodeEntity,
        searchText: String = ""
    ) {
        self.init(
            photo: photo,
            searchText: searchText,
            thumbnailLoader: MockThumbnailLoader(),
            photoSearchResultRouter: MockPhotoSearchResultRouter())
    }
}

@Suite("VisualMediaSearchResultsViewModel Tests")
struct VisualMediaSearchResultsViewModelTestsSuite {
    @Suite("Perform Search")
    @MainActor
    struct PerformSearch {
        @Test("search performed with no results correct empty state shown")
        func noResult() async {
            let visualMediaSearchHistoryUseCase = MockVisualMediaSearchHistoryUseCase(
                searchQueryHistoryEntries: [])
            let monitorAlbumsUseCase = MockMonitorAlbumsUseCase(
                monitorSystemAlbumsSequence: SingleItemAsyncSequence<Result<[AlbumEntity], any Error>>(
                    item: .success([])).eraseToAnyAsyncSequence(),
                monitorUserAlbumsSequence: SingleItemAsyncSequence(
                    item: []).eraseToAnyAsyncSequence()
            )
            let monitorPhotosUseCase = MockMonitorPhotosUseCase(monitorPhotosAsyncSequence: SingleItemAsyncSequence<Result<[NodeEntity], any Error>>(
                item: .success([])).eraseToAnyAsyncSequence())
            let sut = makeSUT(
                visualMediaSearchHistoryUseCase: visualMediaSearchHistoryUseCase,
                monitorAlbumsUseCase: monitorAlbumsUseCase,
                monitorPhotosUseCase: monitorPhotosUseCase
            )
            
            await confirmation { confirmation in
                let monitorSearchTask = Task {
                    await sut.monitorSearchResults()
                }
                let cancellable = sut.$viewState
                    .dropFirst()
                    .sink {
                        #expect($0 == .empty(description: Strings.Localizable.noResults))
                        monitorSearchTask.cancel()
                        confirmation()
                    }
                
                sut.updateSearchText("1")
                
                await monitorSearchTask.value
                cancellable.cancel()
            }
        }
    }
    
    @MainActor
    private static func makeSUT(
        photoAlbumContainerInteractionManager: PhotoAlbumContainerInteractionManager = PhotoAlbumContainerInteractionManager(),
        visualMediaSearchHistoryUseCase: some VisualMediaSearchHistoryUseCaseProtocol = MockVisualMediaSearchHistoryUseCase(),
        monitorAlbumsUseCase: some MonitorAlbumsUseCaseProtocol = MockMonitorAlbumsUseCase(),
        thumbnailLoader: some ThumbnailLoaderProtocol = MockThumbnailLoader(),
        monitorUserAlbumPhotosUseCase: some MonitorUserAlbumPhotosUseCaseProtocol = MockMonitorUserAlbumPhotosUseCase(),
        nodeUseCase: some NodeUseCaseProtocol = MockNodeUseCase(),
        sensitiveNodeUseCase: some SensitiveNodeUseCaseProtocol = MockSensitiveNodeUseCase(),
        sensitiveDisplayPreferenceUseCase: some SensitiveDisplayPreferenceUseCaseProtocol = MockSensitiveDisplayPreferenceUseCase(),
        albumCoverUseCase: some AlbumCoverUseCaseProtocol = MockAlbumCoverUseCase(),
        monitorPhotosUseCase: some MonitorPhotosUseCaseProtocol = MockMonitorPhotosUseCase(),
        photoSearchResultRouter: some PhotoSearchResultRouterProtocol = MockPhotoSearchResultRouter(),
        contentLibrariesConfiguration: ContentLibraries.Configuration = .init(
            sensitiveNodeUseCase: MockSensitiveNodeUseCase(),
            nodeUseCase: MockNodeUseCase(),
            isAlbumPerformanceImprovementsEnabled: { true }),
        searchDebounceTime: DispatchQueue.SchedulerTimeType.Stride = .milliseconds(150)
    ) -> VisualMediaSearchResultsViewModel {
        .init(
            photoAlbumContainerInteractionManager: photoAlbumContainerInteractionManager,
            visualMediaSearchHistoryUseCase: visualMediaSearchHistoryUseCase,
            monitorAlbumsUseCase: monitorAlbumsUseCase,
            thumbnailLoader: thumbnailLoader,
            monitorUserAlbumPhotosUseCase: monitorUserAlbumPhotosUseCase,
            nodeUseCase: nodeUseCase,
            sensitiveNodeUseCase: sensitiveNodeUseCase,
            sensitiveDisplayPreferenceUseCase: sensitiveDisplayPreferenceUseCase,
            albumCoverUseCase: albumCoverUseCase,
            monitorPhotosUseCase: monitorPhotosUseCase,
            photoSearchResultRouter: photoSearchResultRouter,
            contentLibrariesConfiguration: contentLibrariesConfiguration,
            searchDebounceTime: searchDebounceTime)
    }
}
