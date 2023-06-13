import XCTest
import MEGADomain
import MEGADomainMock

final class SearchNodeUseCaseTests: XCTestCase {
    var searchNodeUC: (any SearchNodeUseCaseProtocol)!
    var searchNodeRepo: MockSearchNodeRepository!
    var searchText: String!
    var searchNodes: [NodeEntity]!
    
    override func setUp() {
        super.setUp()
        searchNodes = [NodeEntity(name: "Node1", handle: 1), NodeEntity(name: "Node2", handle: 2)]
        searchNodeRepo = MockSearchNodeRepository(nodes: searchNodes)
        searchNodeUC = SearchNodeUseCase(searchNodeRepository: searchNodeRepo)
        searchText = ""
    }
    
    override func tearDown() {
        searchNodeRepo = nil
        searchNodeUC = nil
        super.tearDown()
    }
    
    func testSearch_foundResults() async throws {
        let expectation = XCTestExpectation(description: "Search completion called with results")
        searchText = "Node"
        let nodes = try await searchNodeUC.search(type: .inShares, text: searchText, sortType: .defaultAsc)
        XCTAssertEqual(nodes, self.filteredNodes(by: self.searchText))
        expectation.fulfill()
        
        await fulfillment(of: [expectation], timeout: 2.0)
    }
    
    func testSearch_noResults() async throws {
        let expectation = XCTestExpectation(description: "Search completion called with no results")
        searchText = "unexpected node"
        let nodes = try await searchNodeUC.search(type: .inShares, text: searchText, sortType: .defaultAsc)
        XCTAssertEqual(nodes, self.filteredNodes(by: self.searchText))
        expectation.fulfill()
        
        await fulfillment(of: [expectation], timeout: 2.0)
    }
    
    func testCancelSearch() async throws {
        let expectation = XCTestExpectation(description: "Cancel search called")
        
        searchNodeUC.cancelSearch()
        
        XCTAssertEqual(searchNodeRepo.cancelSearch_calledTimes, 1)
        expectation.fulfill()
        
        await fulfillment(of: [expectation], timeout: 1.0)
    }
    
    private func filteredNodes(by text: String) -> [NodeEntity]? {
        searchNodes.filter { $0.name.contains(text) }
    }
}
