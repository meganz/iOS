@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGAL10n
import MEGAPresentationMock
import MEGASdk
import MEGASDKRepoMock
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

class HomeSearchProviderTests: XCTestCase {
    
    class Harness {
        let searchFile: MockSearchFileUseCase
        let nodeDetails: MockNodeDetailUseCase
        let nodeDataUseCase: MockNodeDataUseCase
        let mediaUseCase: MockMediaUseCase
        let nodeRepo: MockNodeRepository
        let nodesUpdateListenerRepo: NodesUpdateListenerProtocol
        let sut: HomeSearchResultsProvider
        var receivedFilters: [MEGASearchFilter] = []
        var receivedTimeFrames: [SearchChipEntity.TimeFrame] {
            receivedFilters.compactMap {
                guard let timeFrame = $0.modificationTimeFrame else { return nil }
                let start = Date(timeIntervalSince1970: TimeInterval(timeFrame.lowerLimit))
                let end = Date(timeIntervalSince1970: TimeInterval(timeFrame.upperLimit))
                return .init(
                    startDate: start,
                    endDate: end
                )
            }
        }
        let nodes: [NodeEntity]
        init(
            _ testCase: XCTestCase,
            rootNode: NodeEntity? = nil,
            nodes: [NodeEntity] = [],
            childrenNodes: [NodeEntity] = [],
            file: StaticString = #filePath,
            line: UInt = #line
        ) {
            
            self.nodes = nodes
            searchFile = MockSearchFileUseCase(
                nodes: nodes,
                nodeList: nodes.isNotEmpty ? .init(
                    nodesCount: nodes.count,
                    nodeAt: { nodes[$0] }
                ) : nil,
                nodesToReturnFactory: { _ in
                    .init(nodesCount: 0, nodeAt: { _ in nil })
                }
            )
            nodeDetails = MockNodeDetailUseCase(
                owner: .init(name: "owner"),
                thumbnail: UIImage(systemName: "square.and.arrow.up")
            )

            nodeDataUseCase = MockNodeDataUseCase()

            mediaUseCase = MockMediaUseCase()

            nodeRepo = MockNodeRepository(
                nodeRoot: rootNode,
                childrenNodes: childrenNodes
            )

            nodesUpdateListenerRepo = MockSDKNodesUpdateListenerRepository.newRepo

            sut = HomeSearchResultsProvider(
                parentNodeProvider: {
                    rootNode ?? NodeEntity(handle: 123)
                },
                searchFileUseCase: searchFile,
                nodeDetailUseCase: nodeDetails,
                nodeUseCase: nodeDataUseCase,
                mediaUseCase: mediaUseCase,
                nodeRepository: nodeRepo,
                nodesUpdateListenerRepo: nodesUpdateListenerRepo,
                transferListenerRepo: SDKTransferListenerRepository(sdk: MockSdk()),
                allChips: SearchChipEntity.allChips(
                    areChipsGroupEnabled: true,
                    currentDate: { .testDate },
                    calendar: .testCalendar
                ),
                sdk: MockSdk(),
                onSearchResultUpdated: {_ in}
            )
            
            testCase.trackForMemoryLeaks(on: sut, file: file, line: line)
            
            searchFile.nodesToReturnFactory = {[weak self] filter in
                self?.receivedFilters.append(filter)
                return .init(nodesCount: nodes.count, nodeAt: {
                    nodes[$0]
                })
            }
        }
        
        func propertyIdsForFoundNode() async throws -> Set<NodePropertyId> {
            let searchResults = try await sut.search(
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
            let results = try await sut.search(
                queryRequest: .userSupplied(
                    .init(query: "", sorting: .automatic, mode: .home, isSearchActive: false, chips: [chip])
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
    
    func testSearch_whenTimeChipApplied_searchUseReceivedTimeFrame_returnsValidNodes() async throws {
        let harness = Harness(self, nodes: .anyNodes)
        let timeFrame = SearchChipEntity.TimeFrame(
            startDate: .testDate("05/12/2023 13:55"),
            endDate: .testDate("06/12/2023 12:00")
        )
        let timeChip = SearchChipEntity(
            type: .timeFrame(timeFrame),
            title: "Some time chip"
        )
        try await harness.idsMatch(harness.resultsFor(chip: timeChip))
        
        XCTAssertEqual(harness.receivedTimeFrames, [timeFrame])
    }

    func testSearch_whenFailures_returnsNoResults() async throws {
        let harness = Harness(self)

        let searchResults = try await harness.sut.search(
            queryRequest: .userSupplied(.query("node 1", isSearchActive: true))
        )

        XCTAssertEqual(searchResults?.results, [])
    }
    
    func testSearch_whenInitialQuery_returnsContentsOfRoot() async throws {
        let root = NodeEntity(handle: 1)
        let children = [NodeEntity(handle: 2), NodeEntity(handle: 3), NodeEntity(handle: 4)]
        
        let harness = Harness(self, rootNode: root, childrenNodes: children)
        
        let response = try await harness.sut.search(queryRequest: .initial)
        XCTAssertEqual(response?.results.map(\.id), [2, 3, 4])
    }
    
    func testSearch_whenEmptyQuery_returnsContentsOfRoot() async throws {
        let root = NodeEntity(handle: 1)
        let children = [NodeEntity(handle: 6), NodeEntity(handle: 7), NodeEntity(handle: 8)]
        let harness = Harness(self, rootNode: root, childrenNodes: children)
        
        let response = try await harness.sut.search(queryRequest: .userSupplied(.query("", isSearchActive: false)))
        XCTAssertEqual(response?.results.map(\.id), [6, 7, 8])
    }
    
    func testSearch_whenUsedForUserQuery_usesDefaultAscSortOrder() async throws {
        let root = NodeEntity(handle: 1)
        let children = [NodeEntity(handle: 2)]
        
        let harness = Harness(self, rootNode: root, childrenNodes: children)
        
        _ = try await harness.sut.search(queryRequest: .userSupplied(.query("any search string", isSearchActive: true)))
        XCTAssertEqual(harness.searchFile.passedInSortOrders, [.defaultAsc])
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
        
        let harness = Harness(self, nodes: [
            node
        ])
        
        harness.nodeDataUseCase.labelStringToReturn = "Red"
        let propertyIds = try await harness.propertyIdsForFoundNode()
        XCTAssertEqual(propertyIds, [.label])
    }
    
    func testSearch_resultProperty_isLinked() async throws {
        
        let harness = Harness(self, nodes: [
            .init(name: "node 0", handle: 0, isExported: true)
        ])
        
        harness.nodeDataUseCase.inRubbishBinToReturn = false
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
        
        harness.mediaUseCase.isStringVideoToReturn = true
        let propertyIds = try await harness.propertyIdsForFoundNode()
        XCTAssertEqual(propertyIds, [.videoDuration, .playIcon])
    }
    
    func testSearch_resultProperty_multipleProperties() async throws {
        
        let harness = Harness(self, nodes: [
            .init(name: "node 0", handle: 0, isFile: true, isExported: true)
        ])
        
        harness.nodeDataUseCase.inRubbishBinToReturn = false
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

    func testSearchConfig_whenChipIsDefault_shouldMatch() {
        let emptyAsset = makeEmptyAsset(with: "Title")
        assertSearchConfig(
            expectedAsset: emptyAsset,
            defaultEmptyAsset: emptyAsset,
            searchChipEntity: SearchChipEntity(
                type: .nodeType(1000),
                title: "",
                icon: "",
                subchipsPickerTitle: nil,
                subchips: []
            )
        )
    }

    // MARK: - Private methods.

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
            defaultEmptyViewAsset: defaultEmptyAsset
        )

        let resultEmptyAsset = config.emptyViewAssetFactory(
            searchChipEntity, SearchQuery.userSupplied(.query("", isSearchActive: isSearchActive))
        )
        XCTAssertEqual(resultEmptyAsset, expectedAsset, file: file, line: line)
    }

    private func makeEmptyAsset(with title: String) -> SearchConfig.EmptyViewAssets {
        .init(image: Image(systemName: "person"), title: title, titleTextColor: { _ in .red })
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
