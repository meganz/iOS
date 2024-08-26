import ConcurrencyExtras
@testable import MEGA
import MEGADesignToken
import MEGADomain
import MEGADomainMock
import MEGAL10n
import MEGAPresentationMock
import MEGASdk
import MEGASDKRepoMock
import MEGASwift
import Search
import SearchMock
import SwiftUI
import XCTest

extension Locale {
    static var testLocale: Locale {
        Locale(identifier: "en_US_POSIX")
    }
}

extension TimeZone {
    static var testTimeZone: TimeZone {
        TimeZone(identifier: "UTC")!
    }
}

extension Calendar {
    static var testCalendar: Calendar {
        .init(identifier: .gregorian)
    }
}

extension Array where Element == NodeEntity {
    static var anyNodes: [NodeEntity] {
        [.init(name: "node 0", handle: 0)]
    }
}

fileprivate extension UInt64 {
    static func array(start: UInt64, end: UInt64) -> [UInt64] {
        return Array(start...end)
    }
}

fileprivate extension NodeEntity {
    static func entities(startHandle: UInt64, endHandle: UInt64) -> [NodeEntity] {
        UInt64.array(start: startHandle, end: endHandle).map { NodeEntity(handle: $0) }
    }
}

fileprivate extension Date {
    static func testDate(_ string: String) -> Date {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy HH:mm"
        dateFormatter.locale = .testLocale
        dateFormatter.timeZone = .testTimeZone
        dateFormatter.calendar = .testCalendar
        return dateFormatter.date(from: string)!
    }
    static var testDate: Date {
        return .testDate("06/12/2023 12:00")
    }
}

class HomeSearchResultsProviderTests: XCTestCase {
    
    class Harness {
        static let parentNodeHandle: HandleEntity = 999
        let filesSearchUseCase: MockFilesSearchUseCase
        let nodeDetails: MockNodeDetailUseCase
        let nodeDataUseCase: MockNodeDataUseCase
        let mediaUseCase: MockMediaUseCase
        let nodesUpdateListenerRepo: MockSDKNodesUpdateListenerRepository
        let downloadTransfersListener: MockDownloadTransfersListener
        let contentConsumptionUserAttributeUseCase: MockContentConsumptionUserAttributeUseCase
        let sut: HomeSearchResultsProvider
        let nodes: [NodeEntity]
        
        init(
            _ testCase: XCTestCase,
            nodes: [NodeEntity] = [],
            showHiddenNodes: Bool = false,
            hiddenNodesFeatureEnabled: Bool = true,
            onSearchResultsUpdated: @escaping (SearchResultUpdateSignal) -> Void = { _ in },
            file: StaticString = #filePath,
            line: UInt = #line
        ) {
            let sdk = MockSdk()
            
            self.nodes = nodes
            self.nodeDetails = MockNodeDetailUseCase(
                owner: .init(name: "owner"),
                thumbnail: UIImage(systemName: "square.and.arrow.up")
            )
            let nodeListEntity = NodeListEntity(nodes: nodes)
            filesSearchUseCase = MockFilesSearchUseCase(searchResult: .failure(.generic), nodeListSearchResult: .success(nodeListEntity))
            
            nodeDataUseCase = MockNodeDataUseCase(rootNode: NodeEntity(handle: 1000))

            mediaUseCase = MockMediaUseCase()

            nodesUpdateListenerRepo = MockSDKNodesUpdateListenerRepository.newRepo
            
            downloadTransfersListener = MockDownloadTransfersListener()
             
            contentConsumptionUserAttributeUseCase = MockContentConsumptionUserAttributeUseCase(
                sensitiveNodesUserAttributeEntity: .init(onboarded: false, showHiddenNodes: showHiddenNodes)
            )
            
            sut = HomeSearchResultsProvider(
                parentNodeProvider: { NodeEntity(handle: Harness.parentNodeHandle) },
                filesSearchUseCase: filesSearchUseCase,
                nodeDetailUseCase: nodeDetails,
                nodeUseCase: nodeDataUseCase,
                mediaUseCase: mediaUseCase,
                nodesUpdateListenerRepo: nodesUpdateListenerRepo,
                downloadTransferListener: downloadTransfersListener,
                nodeIconUsecase: MockNodeIconUsecase(stubbedIconData: Data()),
                contentConsumptionUserAttributeUseCase: contentConsumptionUserAttributeUseCase,
                allChips: SearchChipEntity.allChips(
                    currentDate: { .testDate },
                    calendar: .testCalendar
                ),
                sdk: sdk,
                nodeActions: NodeActions.mock(),
                hiddenNodesFeatureEnabled: hiddenNodesFeatureEnabled,
                isDesignTokenEnabled: true,
                onSearchResultsUpdated: onSearchResultsUpdated
            )
            
            testCase.trackForMemoryLeaks(on: sut, file: file, line: line)
        }
        
        func propertyIdsForFoundNode() async throws -> Set<NodePropertyId> {
            let searchResults = await sut.search(
                queryRequest: .userSupplied(.query("node 0", isSearchActive: true))
            )
            let result = try XCTUnwrap(searchResults?.results.first)
            let props = result.properties.compactMap { resultProperty in
                NodePropertyId(rawValue: resultProperty.id)
            }
            return Set(props)
        }
    
        @discardableResult
        func resultsFor(chip: SearchChipEntity) async throws -> [SearchResult] {
            let results = await sut.search(
                queryRequest: .userSupplied(
                    .init(query: "", sorting: .nameAscending, mode: .home, isSearchActive: false, chips: [chip])
                )
            )
            let items = try XCTUnwrap(results)
            return items.results
        }
        
        // we check that results are the same as primed on init
        func idsMatch(_ results: [SearchResult]) {
            XCTAssertEqual(results.map(\.id), nodes.map(\.handle))
        }
    }

    func testSearch_whenFailures_returnsNoResults() async {
        let harness = Harness(self)

        let searchResults = await harness.sut.search(
            queryRequest: .userSupplied(.query("", isSearchActive: true))
        )

        XCTAssertEqual(searchResults?.results, [])
    }
    
    func testSearch_whenInitialQuery_searchWithoutRecursive() async throws {
        // given
        let harness = Harness(self)

        // when
        _ = await harness.sut.search(queryRequest: .initial)

        // then
        XCTAssertEqual(harness.filesSearchUseCase.filters.count, 1)
        let filter = try XCTUnwrap(harness.filesSearchUseCase.filters.first)
        XCTAssertFalse(filter.recursive)
    }
    
    func testSearch_whenEmptyQuery_searchWithoutRecursive() async throws {
        // given
        let harness = Harness(self)

        // when
        _ = await harness.sut.search(queryRequest: .userSupplied(.query("", isSearchActive: false)))

        // then
        XCTAssertEqual(harness.filesSearchUseCase.filters.count, 1)
        let filter = try XCTUnwrap(harness.filesSearchUseCase.filters.first)
        XCTAssertFalse(filter.recursive)
    }
    
    func testSearch_whenNotEmptyQuery_searchWitRecursive() async throws {
        // given
        let harness = Harness(self)
        
        // when
        _ = await harness.sut.search(queryRequest: .userSupplied(.query("foo", isSearchActive: false)))

        // then
        XCTAssertEqual(harness.filesSearchUseCase.filters.count, 1)
        let filter = try XCTUnwrap(harness.filesSearchUseCase.filters.first)
        XCTAssertTrue(filter.recursive)
    }
    
    func testSearch_whenHiddenNodesFeatureEnabledAndShowHiddenNodesSettingIsOn_shouldNotExcludeHiddenNodes() async throws {
        // given
        let harness = Harness(self, showHiddenNodes: true)
        
        // when
        _ = await harness.sut.search(queryRequest: .initial)

        // then
        XCTAssertEqual(harness.filesSearchUseCase.filters.count, 1)
        let filter = try XCTUnwrap(harness.filesSearchUseCase.filters.first)
        XCTAssertEqual(filter.sensitiveFilterOption, .disabled)
    }
    
    func testSearch_whenHiddenNodesFeatureEnabledAndShowHiddenNodesSettingIsOff_shouldExcludeHiddenNodes() async throws {
        // given
        let harness = Harness(self, showHiddenNodes: false)
        
        // when
        _ = await harness.sut.search(queryRequest: .initial)

        // then
        XCTAssertEqual(harness.filesSearchUseCase.filters.count, 1)
        let filter = try XCTUnwrap(harness.filesSearchUseCase.filters.first)
        XCTAssertEqual(filter.sensitiveFilterOption, .nonSensitiveOnly)
    }
    
    func testSearch_whenHiddenNodesFeatureNotEnabledAndShowHiddenNodesSettingIsOn_shouldNotExcludeHiddenNodes() async throws {
        // given
        let harness = Harness(self, showHiddenNodes: true, hiddenNodesFeatureEnabled: false)
        
        // when
        _ = await harness.sut.search(queryRequest: .initial)

        // then
        XCTAssertEqual(harness.filesSearchUseCase.filters.count, 1)
        let filter = try XCTUnwrap(harness.filesSearchUseCase.filters.first)
        XCTAssertEqual(filter.sensitiveFilterOption, .disabled)
    }
    
    func testSearch_nodeType_shouldMatchChipIfSelected() async throws {
        // given
        let query = SearchQuery.userSupplied(.query(chips: [.folders]))
        let harness = Harness(self)
        
        // when
        _ = await harness.sut.search(queryRequest: query)

        // then
        XCTAssertEqual(harness.filesSearchUseCase.filters.count, 1)
        let filter = try XCTUnwrap(harness.filesSearchUseCase.filters.first)
        XCTAssertEqual(filter.nodeTypeEntity, .folder)
    }
    
    func testSearch_nodeType_shouldBeUnknownIfChipNotSelected() async throws {
        // given
        let query = SearchQuery.userSupplied(.query(chips: []))
        let harness = Harness(self)
        
        // when
        _ = await harness.sut.search(queryRequest: query)

        // then
        XCTAssertEqual(harness.filesSearchUseCase.filters.count, 1)
        let filter = try XCTUnwrap(harness.filesSearchUseCase.filters.first)
        XCTAssertEqual(filter.nodeTypeEntity, .unknown)
    }
    
    func testSearch_nodeFormat_shouldMatchChipIfSelected() async throws {
        // given
        let query = SearchQuery.userSupplied(.query(chips: [.audio]))
        let harness = Harness(self)
        
        // when
        _ = await harness.sut.search(queryRequest: query)

        // then
        XCTAssertEqual(harness.filesSearchUseCase.filters.count, 1)
        let filter = try XCTUnwrap(harness.filesSearchUseCase.filters.first)
        XCTAssertEqual(filter.formatType, .audio)
    }
    
    func testSearch_nodeFormat_shouldBeUnknownIfChipNotSelected() async throws {
        // given
        let query = SearchQuery.userSupplied(.query(chips: []))
        let harness = Harness(self)
        
        // when
        _ = await harness.sut.search(queryRequest: query)
        
        // then
        XCTAssertEqual(harness.filesSearchUseCase.filters.count, 1)
        let filter = try XCTUnwrap(harness.filesSearchUseCase.filters.first)
        XCTAssertEqual(filter.formatType, .unknown)
    }
    
    func testSearch_modificationTimeFrame_shouldMatchChipIfSelected() async throws {
        // given
        let timeFrame = SearchChipEntity.TimeFrame(
            startDate: .testDate("16/04/2024 13:55"),
            endDate: .testDate("16/05/2024 12:00")
        )
        let timeChipEntity = SearchChipEntity(
            type: .timeFrame(timeFrame),
            title: "Some time chip"
        )
        let query = SearchQuery.userSupplied(.query(chips: [timeChipEntity]))
        let harness = Harness(self)
        
        // when
        _ = await harness.sut.search(queryRequest: query)

        // then
        XCTAssertEqual(harness.filesSearchUseCase.filters.count, 1)
        let filter = try XCTUnwrap(harness.filesSearchUseCase.filters.first)
        XCTAssertEqual(filter.modificationTimeFrame?.startDate, timeFrame.startDate)
        XCTAssertEqual(filter.modificationTimeFrame?.endDate, timeFrame.endDate)
    }
    
    func testSearch_modificationTimeFrame_shouldBeNilIfChipNotSelected() async throws {
        // given
        let query = SearchQuery.userSupplied(.query(chips: []))
        let harness = Harness(self, showHiddenNodes: true, hiddenNodesFeatureEnabled: false)
        
        // when
        _ = await harness.sut.search(queryRequest: query)

        // then
        XCTAssertEqual(harness.filesSearchUseCase.filters.count, 1)
        let filter = try XCTUnwrap(harness.filesSearchUseCase.filters.first)
        XCTAssertNil(filter.modificationTimeFrame)
    }
    
    func testSearch_whenUsedForUserQuery_usesDefaultAscSortOrder() async throws {
        let harness = Harness(self)

        _ = await harness.sut.search(queryRequest: .userSupplied(.query("any search string", isSearchActive: true)))
        XCTAssertEqual(harness.filesSearchUseCase.filters.count, 1)
        let filter = try XCTUnwrap(harness.filesSearchUseCase.filters.first)
        XCTAssertEqual(filter.sortOrderType, .defaultAsc)
    }
    
    func testSearch_resultProperty_isFavorite() async throws {
        let harness = Harness(self, nodes: [
            .init(name: "node 0", handle: 0, isFavourite: true)
        ])
        let propertyIds = try await harness.propertyIdsForFoundNode()
        XCTAssertEqual(propertyIds, [.favorite])
    }
    
    func testSearch_resultProperty_label() async throws {
        let node = NodeEntity(name: "node 0", handle: 0, label: .red)
        
        let harness = Harness(self, nodes: [node])

        harness.nodeDataUseCase.labelStringToReturn.mutate { $0 = "Red" }
        let propertyIds = try await harness.propertyIdsForFoundNode()
        XCTAssertEqual(propertyIds, [.label])
    }
    
    func testSearch_resultProperty_isLinked() async throws {
        let harness = Harness(self, nodes: [
            .init(name: "node 0", handle: 0, isExported: true)
        ])

        harness.nodeDataUseCase.isNodeInRubbishBin = { _ in false }
        let propertyIds = try await harness.propertyIdsForFoundNode()
        XCTAssertEqual(propertyIds, [.linked])
    }
    
    func testSearch_resultProperty_isVersioned() async throws {
        let harness = Harness(self, nodes: [
            .init(name: "node 0", handle: 0, isFile: true)
        ])

        harness.nodeDataUseCase.versions = true
        let propertyIds = try await harness.propertyIdsForFoundNode()
        XCTAssertEqual(propertyIds, [.versioned])
    }
    
    func testSearch_resultProperty_isDownloaded() async throws {
        let harness = Harness(self, nodes: [
            .init(name: "node 0", handle: 0, isFile: true)
        ])

        harness.nodeDataUseCase.downloadedToReturn = true
        let propertyIds = try await harness.propertyIdsForFoundNode()
        XCTAssertEqual(propertyIds, [.downloaded])
    }
    
    func testSearch_resultProperty_isVideo() async throws {
        let harness = Harness(self, nodes: [
            .init(name: "node 0", handle: 0, duration: 123)
        ])

        harness.mediaUseCase.$isStringVideoToReturn.mutate { $0 = true}
        let propertyIds = try await harness.propertyIdsForFoundNode()
        XCTAssertEqual(propertyIds, [.videoDuration, .playIcon])
    }
    
    func testSearch_resultProperty_multipleProperties() async throws {
        let harness = Harness(self, nodes: [
            .init(name: "node 0", handle: 0, isFile: true, isExported: true)
        ])
        
        harness.nodeDataUseCase.isNodeInRubbishBin = { _ in false }
        harness.nodeDataUseCase.versions = true
        
        let propertyIds = try await harness.propertyIdsForFoundNode()
        XCTAssertEqual(propertyIds, [.versioned, .linked])
    }

    func testSearchConfig_whenSearchIsInactive_shouldMatchTheEmptyAsset() {
        let emptyAsset = makeEmptyAsset(with: "Title")
        assertSearchConfig(expectedAsset: emptyAsset, defaultEmptyAsset: emptyAsset, isSearchActive: false)
    }

    func testSearchConfig_whenSearchIsActive_shouldMatchHomeEmptyNoChipSelected() {
        let expectedAsset = makeEmptyAsset(with: Strings.Localizable.Home.Search.Empty.noChipSelected)
        assertSearchConfig(expectedAsset: expectedAsset, defaultEmptyAsset: makeEmptyAsset(with: "Title"))
    }

    func testSearchConfig_whenChipIsDocs_shouldMatch() {
        assertSearchConfig(
            expectedAsset: makeEmptyAsset(with: Strings.Localizable.Home.Search.Empty.noDocuments),
            defaultEmptyAsset: makeEmptyAsset(with: "Title"),
            searchChipEntity: SearchChipEntity.docs
        )
    }

    func testSearchConfig_whenChipIsAudio_shouldMatch() {
        assertSearchConfig(
            expectedAsset: makeEmptyAsset(with: Strings.Localizable.Home.Search.Empty.noAudio),
            defaultEmptyAsset: makeEmptyAsset(with: "Title"),
            searchChipEntity: SearchChipEntity.audio
        )
    }

    func testSearchConfig_whenChipIsVideo_shouldMatch() {
        assertSearchConfig(
            expectedAsset: makeEmptyAsset(with: Strings.Localizable.Home.Search.Empty.noVideos),
            defaultEmptyAsset: makeEmptyAsset(with: "Title"),
            searchChipEntity: SearchChipEntity.video
        )
    }

    func testSearchConfig_whenChipIsImages_shouldMatch() {
        assertSearchConfig(
            expectedAsset: makeEmptyAsset(with: Strings.Localizable.Home.Search.Empty.noImages),
            defaultEmptyAsset: makeEmptyAsset(with: "Title"),
            searchChipEntity: SearchChipEntity.images
        )
    }

    func testSearchConfig_whenChipIsFolders_shouldMatch() {
        assertSearchConfig(
            expectedAsset: makeEmptyAsset(with: Strings.Localizable.Home.Search.Empty.noFolders),
            defaultEmptyAsset: makeEmptyAsset(with: "Title"),
            searchChipEntity: SearchChipEntity.folders
        )
    }

    func testSearchConfig_whenChipIsPDF_shouldMatch() {
        assertSearchConfig(
            expectedAsset: makeEmptyAsset(with: Strings.Localizable.Home.Search.Empty.noPdfs),
            defaultEmptyAsset: makeEmptyAsset(with: "Title"),
            searchChipEntity: SearchChipEntity.pdf
        )
    }

    func testSearchConfig_whenChipIsPresentation_shouldMatch() {
        assertSearchConfig(
            expectedAsset: makeEmptyAsset(with: Strings.Localizable.Home.Search.Empty.noPresentations),
            defaultEmptyAsset: makeEmptyAsset(with: "Title"),
            searchChipEntity: SearchChipEntity.presentation
        )
    }

    func testSearchConfig_whenChipIsArchives_shouldMatch() {
        assertSearchConfig(
            expectedAsset: makeEmptyAsset(with: Strings.Localizable.Home.Search.Empty.noArchives),
            defaultEmptyAsset: makeEmptyAsset(with: "Title"),
            searchChipEntity: SearchChipEntity.archives
        )
    }

    func testSearchConfig_whenChipIsSpreadsheets_shouldMatch() {
        assertSearchConfig(
            expectedAsset: makeEmptyAsset(with: Strings.Localizable.Home.Search.Empty.noSpreadsheets),
            defaultEmptyAsset: makeEmptyAsset(with: "Title"),
            searchChipEntity: SearchChipEntity.spreadsheets
        )
    }

    func testSearchConfig_whenChipIsDefault_shouldMatch() {
        let emptyAsset = makeEmptyAsset(with: "Title")
        assertSearchConfig(
            expectedAsset: emptyAsset,
            defaultEmptyAsset: emptyAsset,
            searchChipEntity: SearchChipEntity(
                type: .nodeType(.folder),
                title: "",
                icon: "",
                subchipsPickerTitle: nil,
                subchips: []
            )
        )
    }

    func testSearchConfig_WhenTodayIsSelectedAsModifyDateFilter_shouldMatchResults() {
        assertSearchConfig(
            expectedAsset: searchEmptyStateAsset(),
            defaultEmptyAsset: makeEmptyAsset(with: "Title"),
            isSearchActive: false,
            searchChipEntity: .today(calendar: .current, currentDate: .now)
        )
    }

    func testSearchConfig_WhenLastSevenDaysIsSelectedAsModifyDateFilter_shouldMatchResults() {
        assertSearchConfig(
            expectedAsset: searchEmptyStateAsset(),
            defaultEmptyAsset: makeEmptyAsset(with: "Title"),
            isSearchActive: false,
            searchChipEntity: .last7Days(calendar: .current, currentDate: .now)
        )
    }

    func testSearchConfig_WhenLastThirtyDaysIsSelectedAsModifyDateFilter_shouldMatchResults() {
        assertSearchConfig(
            expectedAsset: searchEmptyStateAsset(),
            defaultEmptyAsset: makeEmptyAsset(with: "Title"),
            isSearchActive: false,
            searchChipEntity: .last30Days(calendar: .current, currentDate: .now)
        )
    }

    func testSearchConfig_WhenThisYearIsSelectedAsModifyDateFilter_shouldMatchResults() {
        assertSearchConfig(
            expectedAsset: searchEmptyStateAsset(),
            defaultEmptyAsset: makeEmptyAsset(with: "Title"),
            isSearchActive: false,
            searchChipEntity: .thisYear(calendar: .current, currentDate: .now)
        )
    }

    func testSearchConfig_WhenLastYearIsSelectedAsModifyDateFilter_shouldMatchResults() {
        assertSearchConfig(
            expectedAsset: searchEmptyStateAsset(),
            defaultEmptyAsset: makeEmptyAsset(with: "Title"),
            isSearchActive: false,
            searchChipEntity: .lastYear(currentDate: .now)
        )
    }

    func testSearchConfig_WhenOlderDateIsSelectedAsModifyDateFilter_shouldMatchResults() {
        assertSearchConfig(
            expectedAsset: searchEmptyStateAsset(),
            defaultEmptyAsset: makeEmptyAsset(with: "Title"),
            isSearchActive: false,
            searchChipEntity: .older(currentDate: .now)
        )
    }

    func testSearch_whenLastItemIndexIsAtTheLoadMorePoint_shouldFillMoreItems() async {
        // given
        let nodes = NodeEntity.entities(startHandle: 1, endHandle: 150)
        let harness = Harness(self, nodes: nodes)
        
        // when
        var resultIds = await harness.sut.search(queryRequest: .initial, lastItemIndex: nil)?.results.map(\.id)

        // then
        XCTAssertEqual(resultIds, UInt64.array(start: 1, end: 100))
        
        // when
        resultIds = await harness.sut.search(queryRequest: .initial, lastItemIndex: 81)?.results.map(\.id)

        XCTAssertEqual(resultIds, UInt64.array(start: 101, end: 150))
    }
    
    func testSearch_whenLastItemIndexIsNotAtTheLoadMorePoint_shouldFillMoreItems() async {
        // given
        let nodes = NodeEntity.entities(startHandle: 1, endHandle: 150)
        let harness = Harness(self, nodes: nodes)
        
        // when
        let resultIds = await harness.sut.search(queryRequest: .initial, lastItemIndex: nil)?.results.map(\.id)

        // then
        XCTAssertEqual(resultIds, UInt64.array(start: 1, end: 100))
        
        // when
        let resultEntity = await harness.sut.search(queryRequest: .initial, lastItemIndex: 79)

        XCTAssertNil(resultEntity)
    }
    
    func testSearch_whenAtTheEndOfList_shouldReturnNil() async {
        // given
        let nodes = NodeEntity.entities(startHandle: 1, endHandle: 90)
        let harness = Harness(self, nodes: nodes)
        
        // when
        let resultIds = await harness.sut.search(queryRequest: .initial, lastItemIndex: nil)?.results.map(\.id)

        // then
        XCTAssertEqual(resultIds, UInt64.array(start: 1, end: 90))
        
        // when
        let resultEntity = await harness.sut.search(queryRequest: .initial, lastItemIndex: 90)

        XCTAssertNil(resultEntity)
    }
    
    func testRefreshedSearchResults_whenNotSearchYet_shouldReturnMostPossibleResults() async throws {
        // given
        let nodes = NodeEntity.entities(startHandle: 1, endHandle: 200)
        let harness = Harness(self, nodes: nodes)
        
        // when
        let results = try await harness.sut.refreshedSearchResults(queryRequest: .initial)?.results

        // then
        XCTAssertEqual(results?.count, 100)
    }
    
    func testRefreshedSearchResults_whenThrowError_shouldReturnNil() async throws {
        // given
        let nodes = NodeEntity.entities(startHandle: 1, endHandle: 100)
        let harness = Harness(self, nodes: nodes)
        harness.filesSearchUseCase.updateNodeListSearchResult(.failure(.generic))
        
        do {
            // when
            let resultEntity = try await harness.sut.refreshedSearchResults(queryRequest: .initial)
        } catch {
            guard case FileSearchResultErrorEntity.generic = error else {
                XCTFail("The error should match the FileSearchResultErrorEntity.generic")
                return
            }
        }
    }
    
    func testRefreshedSearchResults_withContinousNodeChanges_shouldReturnCorrectResults() async throws {
        // given: Original folder has a full page of nodes
        var nodes = NodeEntity.entities(startHandle: 1, endHandle: 100)
        
        // when: searchInitially and refresh invoked
        let harness = Harness(self, nodes: nodes)
        _ = try await harness.sut.searchInitially(queryRequest: .initial)
        var resultIds = try await harness.sut.refreshedSearchResults(queryRequest: .initial)?.results.map(\.id)

        // then: Refreshed result should have 100 nodes
        XCTAssertEqual(UInt64.array(start: 1, end: 100), resultIds)
        
        // and when: nodes are reduced to 50 nodes
        nodes.removeLast(50)
        harness.filesSearchUseCase.updateNodeListSearchResult(.success(NodeListEntity(nodes: nodes)))
        resultIds = try await harness.sut.refreshedSearchResults(queryRequest: .initial)?.results.map(\.id)

        // and then: Refreshed result should have 50 nodes
        XCTAssertEqual(UInt64.array(start: 1, end: 50), resultIds)
        
        // and when: nodes are reduced by 10
        nodes.removeFirst(10)
        harness.filesSearchUseCase.updateNodeListSearchResult(.success(NodeListEntity(nodes: nodes)))
        resultIds = try await harness.sut.refreshedSearchResults(queryRequest: .initial)?.results.map(\.id)

        // and then: Refreshed result should have 40 nodes
        XCTAssertEqual(UInt64.array(start: 11, end: 50), resultIds)
        
        // and when: 200 nodes are added
        nodes.append(contentsOf: NodeEntity.entities(startHandle: 51, endHandle: 250))
        harness.filesSearchUseCase.updateNodeListSearchResult(.success(NodeListEntity(nodes: nodes)))
        resultIds = try await harness.sut.refreshedSearchResults(queryRequest: .initial)?.results.map(\.id)

        // and then: Refreshed result should have: 40 orginal
        XCTAssertEqual(UInt64.array(start: 11, end: 50), resultIds)
        
        // and when: Load more results and refresh
        _ = await harness.sut.search(queryRequest: .initial, lastItemIndex: 40)
        resultIds = try await harness.sut.refreshedSearchResults(queryRequest: .initial)?.results.map(\.id)

        // and then: Refreshed result should have: 40 original + 100 loadmore
        XCTAssertEqual(UInt64.array(start: 11, end: 150), resultIds)
        
        // and when: Load more results to the end and refresh
        _ = await harness.sut.search(queryRequest: .initial, lastItemIndex: 130)
        resultIds = try await harness.sut.refreshedSearchResults(queryRequest: .initial)?.results.map(\.id)

        // and then: Refreshed result should have all 240 children nodes
        XCTAssertEqual(UInt64.array(start: 11, end: 250), resultIds)
    }
    
    func testRefreshedSearchResults_withUserSuppliedQuery_shouldReturnUpdatedResults() async throws {
        // given
        let harness = Harness(self, nodes: NodeEntity.entities(startHandle: 1, endHandle: 200))
        
        // when
        let resultIds = try await harness.sut.refreshedSearchResults(queryRequest: .userSupplied(.query("node 0", isSearchActive: false)))?.results.map(\.id)

        // then
        XCTAssertEqual(resultIds?.count, 100)
    }
    
    func testRefreshedSearchResults_withUserSuppliedQueryShowRoot_shouldReturnUpdatedResults() async throws {
        // given
        let harness = Harness(self, nodes: NodeEntity.entities(startHandle: 1, endHandle: 200))
        // when
        let resultIds = try await harness.sut.refreshedSearchResults(queryRequest: .userSupplied(.query("", isSearchActive: false)))?.results.map(\.id)

        // then
        XCTAssertEqual(resultIds?.count, 100)
    }
    
    func testNodeUpdatesListener_whenNodeUpdateIsNotNeeded_shouldNotProcessNodeUpdates() async {
        // given
        let nodes = NodeEntity.entities(startHandle: 1, endHandle: 3)
        
        var nodeUpdatesSignals = [SearchResultUpdateSignal]()
        
        let harness = Harness(self, nodes: nodes, onSearchResultsUpdated: {
            nodeUpdatesSignals.append($0)
        })
        
        // when
        harness.nodesUpdateListenerRepo.onNodesUpdateHandler?(nodes)
        
        // then
        XCTAssertTrue(nodeUpdatesSignals.isEmpty)
    }
    
    func testNodeUpdatesListener_whenShouldProcessNodesUpdate_shouldProcessNodeUpdates() async {
        // given
        let nodes = NodeEntity.entities(startHandle: 1, endHandle: 2)
        
        var nodeUpdatesSignals = [SearchResultUpdateSignal]()
        
        let expectation = expectation(description: "Waiting node updates signal")
        
        let harness = Harness(self, nodes: nodes, onSearchResultsUpdated: {
            nodeUpdatesSignals.append($0)
            if nodeUpdatesSignals.count == 2 {
                expectation.fulfill()
            }
        })
        _ = await harness.sut.search(queryRequest: .initial, lastItemIndex: nil)

        let task = Task {
            await harness.sut.listenToSpecificResultUpdates()
        }
        
        // when
        
        harness.nodesUpdateListenerRepo.onNodesUpdateHandler?([.init(parentHandle: Harness.parentNodeHandle)]) // Trigger .generic signal
        harness.downloadTransfersListener.simulateDownloadedNode(nodes[1]) // Trigger .specific signal
        
        await fulfillment(of: [expectation], timeout: 1.0)
        task.cancel()
        // then
        guard case .generic = nodeUpdatesSignals[0] else {
            XCTFail("Expecting .generic update signal")
            return
        }
        
        guard case let .specific(result) = nodeUpdatesSignals[1] else {
            XCTFail("Expecting .specific update signal")
            return
        }
        
        XCTAssertEqual(result.id, 2)
    }

    func testSearchInitially_withNodeAsRubbishBinRootWhenShowHiddenItemsUISettingIsEnabled_noSensitiveFilterApplied() async throws {
        try await assertSearchInitially(withShowHiddenItemsUISetting: true) {
            $0.nodeDataUseCase.isARubbishBinRootNodeValue = true
        }
    }

    func testSearchInitially_withNodeAsRubbishBinRootWhenShowHiddenItemsUISettingIsDisabled_noSensitiveFilterApplied() async throws {
        try await assertSearchInitially(withShowHiddenItemsUISetting: false) {
            $0.nodeDataUseCase.isARubbishBinRootNodeValue = true
        }
    }

    func testSearchInitially_withNodeInRubbishBinWhenShowHiddenItemsUISettingIsEnabled_noSensitiveFilterApplied() async throws {
        try await assertSearchInitially(withShowHiddenItemsUISetting: true) {
            $0.nodeDataUseCase.isNodeInRubbishBin = { _ in true }
        }
    }

    func testSearchInitially_withNodeInRubbishBinWhenShowHiddenItemsUISettingIsDisabled_noSensitiveFilterApplied() async throws {
        try await assertSearchInitially(withShowHiddenItemsUISetting: false) {
            $0.nodeDataUseCase.isNodeInRubbishBin = { _ in true }
        }
    }

    // MARK: - Private methods.

    private func assertSearchInitially(
        withShowHiddenItemsUISetting enabled: Bool,
        harnessSetup: (Harness) -> Void,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async throws {
        // given
        let harness = Harness(self, showHiddenNodes: enabled, hiddenNodesFeatureEnabled: true)
        harnessSetup(harness)

        // when
        _ = try await harness.sut.searchInitially(queryRequest: .initial)

        // then
        let filters = harness.filesSearchUseCase.filters
        XCTAssertEqual(filters.first?.sensitiveFilterOption, .disabled, file: file, line: line)
    }

    private func assertSearchConfig(
        expectedAsset: SearchConfig.EmptyViewAssets,
        defaultEmptyAsset: SearchConfig.EmptyViewAssets,
        isSearchActive: Bool = true,
        searchChipEntity: SearchChipEntity? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let config = SearchConfig.searchConfig(
            contextPreviewFactory: HomeScreenFactory().contextPreviewFactory(
                enableItemMultiSelection: false
            ),
            defaultEmptyViewAsset: { defaultEmptyAsset }
        )

        let resultEmptyAsset = config.emptyViewAssetFactory(
            searchChipEntity, SearchQuery.userSupplied(.query("", isSearchActive: isSearchActive))
        )
        XCTAssertEqual(resultEmptyAsset, expectedAsset, file: file, line: line)
    }

    private func makeEmptyAsset(with title: String) -> SearchConfig.EmptyViewAssets {
        .init(image: Image(systemName: "person"), title: title, titleTextColor: { _ in .red })
    }

    private func searchEmptyStateAsset() -> SearchConfig.EmptyViewAssets {
        let titleTextColor: (ColorScheme) -> Color = { colorScheme in
            guard UIColor.isDesignTokenEnabled() else {
                return colorScheme == .light ? UIColor.gray515151.swiftUI : UIColor.grayD1D1D1.swiftUI
            }

            return TokenColors.Icon.secondary.swiftUI
        }

        return .init(
            image: Image(.searchEmptyState),
            title: Strings.Localizable.Home.Search.Empty.noChipSelected,
            titleTextColor: titleTextColor
        )
    }
}

extension SearchConfig.EmptyViewAssets: Equatable {
    public static func == (lhs: Search.SearchConfig.EmptyViewAssets, rhs: Search.SearchConfig.EmptyViewAssets) -> Bool {
        lhs.title == rhs.title && lhs.actions == rhs.actions
    }
}

extension SearchConfig.EmptyViewAssets.Action: Equatable {
    public static func == (lhs: SearchConfig.EmptyViewAssets.Action, rhs: SearchConfig.EmptyViewAssets.Action) -> Bool {
        lhs.title == rhs.title && lhs.menu == rhs.menu
    }
}

extension SearchConfig.EmptyViewAssets.MenuOption: Equatable {
    public static func == (
        lhs: SearchConfig.EmptyViewAssets.MenuOption, rhs: SearchConfig.EmptyViewAssets.MenuOption
    ) -> Bool {
        lhs.title == rhs.title
    }
}

extension NodeListEntity {
    public init(nodes: [NodeEntity]) {
        self.init(nodesCount: nodes.count, nodeAt: { nodes[safe: $0] })
    }
}

extension NodeActions {
    static func mock() -> Self {
        .init(
            nodeDownloader: { _ in },
            editTextFile: { _ in },
            shareOrManageLink: { _ in },
            showNodeInfo: { _ in },
            assignLabel: { _ in },
            toggleNodeFavourite: { _ in },
            sendToChat: { _ in },
            saveToPhotos: { _ in },
            exportFiles: { _, _ in },
            browserAction: { _, _ in },
            userProfileOpener: { _ in },
            removeLink: { _ in },
            removeSharing: { _ in },
            rename: { _, _ in },
            shareFolders: { _ in },
            leaveSharing: { _ in },
            manageShare: { _ in },
            showNodeVersions: { _ in },
            disputeTakedown: { _ in },
            moveToRubbishBin: { _ in },
            restoreFromRubbishBin: { _ in },
            removeFromRubbishBin: { _ in },
            hide: { _ in },
            unhide: { _ in }
        )
    }
}
