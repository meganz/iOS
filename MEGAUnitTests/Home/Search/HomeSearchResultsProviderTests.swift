@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGAPresentationMock
import MEGASdk
import MEGASDKRepoMock
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
        let nodesUpdateListenerRepo: NodesUpdateListenerProtocol
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

            nodesUpdateListenerRepo = MockSDKNodesUpdateListenerRepository.newRepo

            sut = HomeSearchResultsProvider(
                searchFileUseCase: searchFile,
                nodeDetailUseCase: nodeDetails,
                nodeUseCase: nodeDataUseCase,
                mediaUseCase: mediaUseCase,
                nodeRepository: nodeRepo,
                featureFlagProvider: MockFeatureFlagProvider(list: [:]),
                nodesUpdateListenerRepo: nodesUpdateListenerRepo,
                sdk: MockSdk(), 
                onSearchResultUpdated: {_ in}
            )
            
            testCase.trackForMemoryLeaks(on: sut, file: file, line: line)
        }
        
        func propertyIdsForFoundNode() async throws -> Set<NodePropertyId> {
            let searchResults = try await sut.search(
                queryRequest: .userSupplied(.query("node 0"))
            )
            let result = try XCTUnwrap(searchResults?.results.first)
            let props = result.properties.compactMap { resultProperty in
                NodePropertyId(rawValue: resultProperty.id)
            }
            return Set(props)
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
    
}
