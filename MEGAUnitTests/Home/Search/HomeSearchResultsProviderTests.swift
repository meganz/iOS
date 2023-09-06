@testable import MEGA
import MEGADomain
import MEGADomainMock
import Search
import SearchMock
import XCTest

class HomeSearchProviderTests: XCTestCase {
    class Harness {
        let searchFile: MockSearchFileUseCase
        let nodeDetails: MockNodeDetailUseCase
        let nodeRepo: MockNodeRepository
        let sut: HomeSearchResultsProvider
        
        init(
            _ testCase: XCTestCase,
            nodes: [NodeEntity] = [],
            childrenNodes: [NodeEntity] = [],
            file: StaticString = #filePath,
            line: UInt = #line
        ) {
            
            searchFile = MockSearchFileUseCase(
                nodes: nodes
            )
            nodeDetails = MockNodeDetailUseCase(
                owner: .init(name: "owner"),
                thumbnail: UIImage(systemName: "square.and.arrow.up")
            )
            
            nodeRepo = MockNodeRepository(
                childrenNodes: childrenNodes
            )
            
            sut = HomeSearchResultsProvider(
                searchFileUseCase: searchFile,
                nodeDetailUseCase: nodeDetails,
                nodeRepository: nodeRepo
            )
            
            testCase.trackForMemoryLeaks(on: sut, file: file, line: line)
        }
    }
    func testSearch_whenSuccess_returnsResults() async throws {
        let harness = Harness(self, nodes: [
            .init(name: "node 0", handle: 0),
            .init(name: "node 1", handle: 1),
            .init(name: "node 2", handle: 2),
            .init(name: "node 10", handle: 10)
        ])

        let searchResults = try await harness.sut.search(
            queryRequest: .query("node 1") // we should match `node 1` and `node 10`
        )

        XCTAssertEqual(searchResults.results.map(\.id), [1, 10])
    }

    func testSearch_whenFailures_returnsNoResults() async throws {
        let harness = Harness(self)

        let searchResults = try await harness.sut.search(
            queryRequest: .query("node 1")
        )

        XCTAssertEqual(searchResults.results, [])
    }
    
    func testSearch_whenEmptyQuery_returnsEmptyResults() async throws {
        let root = NodeEntity(handle: 1)
        let child = NodeEntity(handle: 2)
        let harness = Harness(self, nodes: [root], childrenNodes: [child])
        let response = try await harness.sut.search(queryRequest: .query(""))
        XCTAssertEqual(response.results, [])
    }
}
