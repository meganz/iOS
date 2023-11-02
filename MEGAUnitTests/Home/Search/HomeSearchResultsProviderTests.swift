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
        let nodeDataUseCase: MockNodeDataUseCase
        let mediaUseCase: MockMediaUseCase
        let nodeRepo: MockNodeRepository
        let sut: HomeSearchResultsProvider
        
        init(
            _ testCase: XCTestCase,
            rootNode: NodeEntity? = nil,
            nodes: [NodeEntity] = [],
            childrenNodes: [NodeEntity] = [],
            file: StaticString = #filePath,
            line: UInt = #line
        ) {
            
            searchFile = MockSearchFileUseCase(
                nodes: nodes,
                nodeList: nodes.isNotEmpty ? .init(
                    nodesCount: nodes.count,
                    nodeAt: { nodes[$0] }
                ) : nil
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
            
            sut = HomeSearchResultsProvider(
                searchFileUseCase: searchFile,
                nodeDetailUseCase: nodeDetails,
                nodeUseCase: nodeDataUseCase,
                mediaUseCase: mediaUseCase,
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
            queryRequest: .userSupplied(.query("node 1")) // we should match `node 1` and `node 10`
        )

        XCTAssertEqual(searchResults?.results.map(\.id), [1, 10])
    }

    func testSearch_whenFailures_returnsNoResults() async throws {
        let harness = Harness(self)

        let searchResults = try await harness.sut.search(
            queryRequest: .userSupplied(.query("node 1"))
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
        
        let response = try await harness.sut.search(queryRequest: .userSupplied(.query("")))
        XCTAssertEqual(response?.results.map(\.id), [6, 7, 8])
    }
    
    func testSearch_whenUsedForUserQuery_usesDefaultAscSortOrder() async throws {
        let root = NodeEntity(handle: 1)
        let children = [NodeEntity(handle: 2)]
        
        let harness = Harness(self, rootNode: root, childrenNodes: children)
        
        _ = try await harness.sut.search(queryRequest: .userSupplied(.query("any search string")))
        XCTAssertEqual(harness.searchFile.passedInSortOrders, [.defaultAsc])
    }
}
