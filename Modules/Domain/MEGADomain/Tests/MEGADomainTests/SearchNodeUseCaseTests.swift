import MEGADomain
import MEGADomainMock
import XCTest

final class SharedItemsSearchNodeUseCaseTests: XCTestCase {
    var searchNodeUC: (any SharedItemsSearchNodeUseCaseProtocol)!
    var filesSearchRepo: MockFilesSearchRepository!
    var searchText: String!
    
    override func setUp() {
        super.setUp()
        let nodesForLocation: [FolderTargetEntity: [NodeEntity]] = [
            .inShare: [NodeEntity(name: "Node1", handle: 1, isFile: true), NodeEntity(name: "Node2", handle: 2, isFile: true)],
            .outShare: [NodeEntity(name: "Node3", handle: 3, isFile: true), NodeEntity(name: "Node4", handle: 4, isFile: true)],
            .publicLink: [NodeEntity(name: "Node5", handle: 5, isFile: true), NodeEntity(name: "Node6", handle: 6, isFile: true)]
        ]
        filesSearchRepo = MockFilesSearchRepository(nodesForLocation: nodesForLocation)
        searchNodeUC = SharedItemsSearchNodeUseCase(filesSearchRepository: filesSearchRepo)
        searchText = ""
    }
    
    override func tearDown() {
        filesSearchRepo = nil
        searchNodeUC = nil
        super.tearDown()
    }
    
    func testSearch_foundResults() async throws {
        try await expectResults([1, 2], whenSearchingFor: "Node", description: "Desc", tag: "tag", searchNodeType: .inShares)
        try await expectResults([3, 4], whenSearchingFor: "Node", description: "Desc", tag: "tag", searchNodeType: .outShares)
        try await expectResults([5, 6], whenSearchingFor: "Node", description: "Desc", tag: "tag", searchNodeType: .publicLinks)
    }
    
    func testCancelSearch() async throws {
        searchNodeUC.cancelSearch()
        XCTAssertTrue(filesSearchRepo.hasCancelSearchCalled)
    }
    
    private func expectResults(
        _ nodeHandles: [HandleEntity],
        whenSearchingFor searchText: String,
        description: String?,
        tag: String?,
        searchNodeType: SharedItemsSearchSourceTypeEntity
    ) async throws {
        let nodes = try await searchNodeUC.search(
            type: searchNodeType,
            text: searchText,
            description: description,
            tag: tag,
            sortType: .defaultAsc
        )
        XCTAssertEqual(nodes.map(\.handle), nodeHandles)
        let searchFilter = filesSearchRepo.searchedFilters.last
        XCTAssertEqual(searchFilter?.searchText, searchText)
        XCTAssertEqual(searchFilter?.searchDescription, description)
        XCTAssertEqual(searchFilter?.searchTag, tag)
    }
}
