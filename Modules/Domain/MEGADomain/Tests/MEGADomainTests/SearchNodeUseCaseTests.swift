import MEGADomain
import MEGADomainMock
import XCTest

final class SearchNodeUseCaseTests: XCTestCase {
    var searchNodeUC: (any SearchNodeUseCaseProtocol)!
    var filesSearchRepo: MockFilesSearchRepository!
    var searchText: String!
    
    override func setUp() {
        super.setUp()
        let nodesForLocation: [FolderTargetEntity: [NodeEntity]] = [
            .inShare: [NodeEntity(name: "Node1", handle: 1), NodeEntity(name: "Node2", handle: 2)],
            .outShare: [NodeEntity(name: "Node3", handle: 3), NodeEntity(name: "Node4", handle: 4)],
            .publicLink: [NodeEntity(name: "Node5", handle: 5), NodeEntity(name: "Node6", handle: 6)]
        ]
        filesSearchRepo = MockFilesSearchRepository(nodesForLocation: nodesForLocation)
        searchNodeUC = SearchNodeUseCase(filesSearchRepository: filesSearchRepo)
        searchText = ""
    }
    
    override func tearDown() {
        filesSearchRepo = nil
        searchNodeUC = nil
        super.tearDown()
    }
    
    func testSearch_foundResults() async throws {
        try await expectResults([1, 2], whenSearchingFor: "Node", searchNodeType: .inShares)
        try await expectResults([3, 4], whenSearchingFor: "Node", searchNodeType: .outShares)
        try await expectResults([5, 6], whenSearchingFor: "Node", searchNodeType: .publicLinks)
    }
    
    func testCancelSearch() async throws {
        searchNodeUC.cancelSearch()
        XCTAssertTrue(filesSearchRepo.hasCancelSearchCalled)
    }
    
    private func expectResults(_ nodeHandles: [HandleEntity], whenSearchingFor searchText: String, searchNodeType: SearchNodeTypeEntity) async throws {
        let nodes = try await searchNodeUC.search(type: searchNodeType, text: searchText, sortType: .defaultAsc)
        XCTAssertEqual(nodes.map(\.handle), nodeHandles)
    }
}
