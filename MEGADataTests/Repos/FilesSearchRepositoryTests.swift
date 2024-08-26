import Combine
@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGASDKRepo
import MEGASDKRepoMock
import XCTest

final class FilesSearchRepositoryTests: XCTestCase {
    
    private let rootNode = MockNode(handle: 0, name: "root")
    private var subscriptions = Set<AnyCancellable>()
    
    func testStartMonitoring_onAlbumScreen_shouldSetCallBack() {
        let sdk = MockSdk()
        let repo = FilesSearchRepository(sdk: sdk)
        
        repo.startMonitoringNodesUpdate(callback: { _ in })
        
        XCTAssertTrue(sdk.hasGlobalDelegate)
    }
    
    func testStopMonitoring_onAlbumScreen_shouldSetCallBackToNil() {
        let sdk = MockSdk()
        let repo = FilesSearchRepository(sdk: sdk)
        
        repo.stopMonitoringNodesUpdate()
        
        XCTAssertFalse(sdk.hasGlobalDelegate)
    }
    
    func testFetchNodeForHandle_onRetrieval_shouldMapToNodeEnity() async {
        let handle = HandleEntity(25)
        let mockNode = MockNode(handle: handle)
        let repo = FilesSearchRepository(sdk: MockSdk(nodes: [mockNode]))
        let result = await repo.node(by: handle)
        XCTAssertEqual(result, mockNode.toNodeEntity())
    }
    
    func testOnNodesUpdate_whenCallbackProvided_shouldCallCallback() {
        let handle = HandleEntity(25)
        let mockNode = MockNode(handle: handle)
        let mockNodeList = MockNodeList(nodes: [mockNode])
        let mockSdk = MockSdk(nodes: [mockNode])
        let repo = FilesSearchRepository(sdk: mockSdk)
        
        let exp = expectation(description: "Calling callback should be successful")
        
        repo.startMonitoringNodesUpdate { nodes in
            XCTAssertEqual([mockNode.toNodeEntity()], nodes)
            exp.fulfill()
        }
        
        repo.onNodesUpdate(mockSdk, nodeList: mockNodeList)
        wait(for: [exp], timeout: 1.0)
    }
    
    func testOnNodesUpdate_whenCallbackNotProvided_shouldUsePublisher() {
        let handle = HandleEntity(25)
        let mockNode = MockNode(handle: handle)
        let mockNodeList = MockNodeList(nodes: [mockNode])
        let mockSdk = MockSdk(nodes: [mockNode])
        let repo = FilesSearchRepository(sdk: mockSdk)
        
        let exp = expectation(description: "Using publisher should be successful")
        
        repo.nodeUpdatesPublisher.sink { nodes in
            XCTAssertEqual([mockNode.toNodeEntity()], nodes)
            exp.fulfill()
        }.store(in: &subscriptions)
        
        repo.startMonitoringNodesUpdate(callback: nil)
        repo.onNodesUpdate(mockSdk, nodeList: mockNodeList)
        wait(for: [exp], timeout: 1.0)
    }
    
    func testSearch_onSuccessAndExcludeSensitveEqualTrue_shouldCallWithCorrectQueryParameters() async throws {
        let parent = MockNode(handle: 1)
        let nodes = [parent,
                     MockNode(handle: 34),
                     MockNode(handle: 65)]
        let mockSdk = MockSdk(nodes: nodes)
        let repo = FilesSearchRepository(sdk: mockSdk)
        let searchString = "*"
        let recursive = true
        let sortOrderType = SortOrderEntity.defaultAsc
        let formatType = NodeFormatEntity.photo
        let sensitiveFilter = SearchFilterEntity.SensitiveFilterOption.nonSensitiveOnly

        let expectedSearchQuery = MockSdk.SearchQueryParameters(node: parent,
                                                                searchString: searchString,
                                                                recursive: recursive,
                                                                sortOrderType: sortOrderType.toMEGASortOrderType(),
                                                                formatType: formatType.toMEGANodeFormatType(), 
                                                                sensitiveFilter: sensitiveFilter.toMEGASearchFilterSensitiveOption(),
                                                                favouriteFilter: .disabled)
        
        let result: NodeListEntity = try await repo.search(filter: .recursive(
            searchText: searchString,
            searchTargetLocation: .parentNode(parent.toNodeEntity()),
            supportCancel: false,
            sortOrderType: sortOrderType,
            formatType: formatType,
            sensitiveFilterOption: sensitiveFilter))
        
        XCTAssertEqual(result.toNodeEntities(), nodes.toNodeEntities())
        XCTAssertEqual(mockSdk.searchNonRecursivelyWithFilterCallCount, 0)
        XCTAssertEqual(mockSdk.searchWithFilterCallCount, 1)
        XCTAssertEqual(mockSdk.searchQueryParameters, expectedSearchQuery)
    }
    
    func testSearch_onSuccessAndExcludeSensitveEqualTrueAndWithoutRecursive_shouldCallWithCorrectQueryParameters() async throws {
        let parent = MockNode(handle: 1)
        let nodes = [parent,
                     MockNode(handle: 34),
                     MockNode(handle: 65)]
        let mockSdk = MockSdk(nodes: nodes)
        let repo = FilesSearchRepository(sdk: mockSdk)
        let searchString = "*"
        let recursive = false
        let sortOrderType = SortOrderEntity.defaultAsc
        let formatType = NodeFormatEntity.photo
        let sensitiveFilter = SearchFilterEntity.SensitiveFilterOption.nonSensitiveOnly
        
        let expectedSearchQuery = MockSdk.SearchQueryParameters(node: parent,
                                                                searchString: searchString,
                                                                recursive: recursive,
                                                                sortOrderType: sortOrderType.toMEGASortOrderType(),
                                                                formatType: formatType.toMEGANodeFormatType(),
                                                                sensitiveFilter: sensitiveFilter.toMEGASearchFilterSensitiveOption(),
                                                                favouriteFilter: .disabled)
        
        let result: NodeListEntity = try await repo.search(filter: .nonRecursive(
            searchText: searchString,
            searchTargetNode: parent.toNodeEntity(),
            supportCancel: false,
            sortOrderType: sortOrderType,
            formatType: formatType,
            sensitiveFilterOption: sensitiveFilter)
        )
        
        XCTAssertEqual(result.toNodeEntities(), nodes.toNodeEntities())
        XCTAssertEqual(mockSdk.searchNonRecursivelyWithFilterCallCount, 1)
        XCTAssertEqual(mockSdk.searchWithFilterCallCount, 0)
        XCTAssertEqual(mockSdk.searchQueryParameters, expectedSearchQuery)
    }
    
    func testSearch_onSuccessAndFiltersFavourites_shouldCallWithCorrectQueryParameters() async throws {
        let parent = MockNode(handle: 1)
        let nodes = [parent,
                     MockNode(handle: 34),
                     MockNode(handle: 65)]
        let mockSdk = MockSdk(nodes: nodes)
        let repo = FilesSearchRepository(sdk: mockSdk)
        let searchString = "*"
        let recursive = false
        let sortOrderType = SortOrderEntity.defaultAsc
        let formatType = NodeFormatEntity.photo
        let sensitiveFilter = SearchFilterEntity.SensitiveFilterOption.nonSensitiveOnly

        let expectedSearchQuery = MockSdk.SearchQueryParameters(node: parent,
                                                                searchString: searchString,
                                                                recursive: recursive,
                                                                sortOrderType: sortOrderType.toMEGASortOrderType(),
                                                                formatType: formatType.toMEGANodeFormatType(),
                                                                sensitiveFilter: sensitiveFilter.toMEGASearchFilterSensitiveOption(),
                                                                favouriteFilter: .favouritesOnly)
        
        let result: NodeListEntity = try await repo.search(filter: .nonRecursive(
            searchText: searchString,
            searchTargetNode: parent.toNodeEntity(),
            supportCancel: false,
            sortOrderType: sortOrderType,
            formatType: formatType,
            sensitiveFilterOption: sensitiveFilter,
            favouriteFilterOption: .onlyFavourites)
        )
        
        XCTAssertEqual(result.toNodeEntities(), nodes.toNodeEntities())
        XCTAssertEqual(mockSdk.searchNonRecursivelyWithFilterCallCount, 1)
        XCTAssertEqual(mockSdk.searchWithFilterCallCount, 0)
        XCTAssertEqual(mockSdk.searchQueryParameters, expectedSearchQuery)
    }
    
    func testSearch_onSuccessWithPaged_shouldCallWithCorrectQueryParameters() async throws {
        let parent = MockNode(handle: 1)
        let nodes = [parent,
                     MockNode(handle: 34),
                     MockNode(handle: 65)]
        let mockSdk = MockSdk(nodes: nodes)
        let repo = FilesSearchRepository(sdk: mockSdk)
        let searchString = "*"
        let recursive = false
        let sortOrderType = SortOrderEntity.defaultAsc
        let formatType = NodeFormatEntity.photo
        let sensitiveFilter = SearchFilterEntity.SensitiveFilterOption.nonSensitiveOnly
        
        let expectedSearchQuery = MockSdk.SearchQueryParameters(node: parent,
                                                                searchString: searchString,
                                                                recursive: recursive,
                                                                sortOrderType: sortOrderType.toMEGASortOrderType(),
                                                                formatType: formatType.toMEGANodeFormatType(),
                                                                sensitiveFilter: sensitiveFilter.toMEGASearchFilterSensitiveOption(),
                                                                favouriteFilter: .favouritesOnly,
                                                                pageOffset: 0,
                                                                pageSize: 2)
        
        let result: NodeListEntity = try await repo.search(
            filter: .nonRecursive(
                searchText: searchString,
                searchTargetNode: parent.toNodeEntity(),
                supportCancel: false,
                sortOrderType: sortOrderType,
                formatType: formatType,
                sensitiveFilterOption: sensitiveFilter,
                favouriteFilterOption: .onlyFavourites),
            page: .init(startingOffset: 0, pageSize: 2)
        )
        
        XCTAssertEqual(result.toNodeEntities(), nodes.toNodeEntities())
        XCTAssertEqual(mockSdk.searchNonRecursivelyWithFilterCallCount, 1)
        XCTAssertEqual(mockSdk.searchWithFilterCallCount, 0)
        XCTAssertEqual(mockSdk.searchQueryParameters, expectedSearchQuery)
    }
    
    func testSearch_recurisveNonSensitiveNodesOnParentMarkedAsSensitiveOrInheritingSensitive_shouldReturnEmptyListWithoutCallingSDK() async throws {
        for (isMarkedSensitive, isInheritingSensitive) in [(isMarkedSensitive: true, isInheritingSensitive: false),
                                                           (isMarkedSensitive: false, isInheritingSensitive: true)] {
            let parent = MockNode(handle: 1, isMarkedSensitive: isMarkedSensitive)
            let mockSdk = MockSdk(nodes: [parent], isNodeInheritingSensitivity: isInheritingSensitive)
            let repo = FilesSearchRepository(sdk: mockSdk)
            
            let result: NodeListEntity = try await repo.search(
                filter: .recursive(
                    searchText: "",
                    searchTargetLocation: .parentNode(parent.toNodeEntity()),
                    supportCancel: false,
                    sortOrderType: anySortOrderType(),
                    formatType: anyFormatType(),
                    sensitiveFilterOption: .nonSensitiveOnly)
            )
            
            XCTAssertTrue(result.toNodeEntities().isEmpty,
                          "Expected empty list for isMarkedSensitive: \(isMarkedSensitive) and isInheritingSensitive: \(isInheritingSensitive)")
            XCTAssertEqual(mockSdk.searchNonRecursivelyWithFilterCallCount, 0,
                           "Expected no recursive calls for isMarkedSensitive: \(isMarkedSensitive) and isInheritingSensitive: \(isInheritingSensitive)")
            XCTAssertEqual(mockSdk.searchWithFilterCallCount, 0,
                           "Expected no search calls for isMarkedSensitive: \(isMarkedSensitive) and isInheritingSensitive: \(isInheritingSensitive)")
        }
    }
    
    // MARK: Private
    
    private func photoNodes() -> [MockNode] {
        [MockNode(handle: 1, name: "1.raw"),
         MockNode(handle: 2, name: "2.nef"),
         MockNode(handle: 3, name: "3.cr2"),
         MockNode(handle: 4, name: "4.dng"),
         MockNode(handle: 5, name: "5.gif")]
    }
    
    private func videoNodes() -> [MockNode] {
        [MockNode(handle: 1, name: "1.mp4"),
         MockNode(handle: 2, name: "2.mov")]
    }
    
    private func anySortOrderType() -> SortOrderEntity {
        SortOrderEntity.allCases.randomElement() ??  .creationAsc
    }
    
    private func anyFormatType() -> NodeFormatEntity {
        .photo
    }
}
