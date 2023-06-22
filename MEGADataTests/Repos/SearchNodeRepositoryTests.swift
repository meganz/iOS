@testable import MEGA
import MEGADataMock
import MEGADomain
import MEGADomainMock
import XCTest

final class SearchNodeRepositoryTests: XCTestCase {
    var incomingNodes: [MockNode]!
    var outgoingNodes: [MockNode]!
    var publicLinksNodes: [MockNode]!
    var repo: SearchNodeRepository!
    
    override func setUp() {
        super.setUp()
        incomingNodes = [MockNode(handle: 1, name: "test_incoming_1"),
                         MockNode(handle: 2, name: "test_incoming_2"),
                         MockNode(handle: 3, name: "test_incoming_3")
        ]
        
        outgoingNodes = [MockNode(handle: 4, name: "test_outshares_1"),
                         MockNode(handle: 5, name: "test_outshares_2"),
                         MockNode(handle: 6, name: "test_outshares_3")
        ]
        
        publicLinksNodes = [MockNode(handle: 7, name: "test_public_link_1"),
                            MockNode(handle: 8, name: "test_public_link_2"),
                            MockNode(handle: 9, name: "test_public_link_3")
        ]
        
        repo = SearchNodeRepository(sdk: MockSdk(incomingNodes: MockNodeList(nodes: incomingNodes), outgoingNodes: MockNodeList(nodes: outgoingNodes), publicLinkNodes: MockNodeList(nodes: publicLinksNodes)))
    }
    
    private func filterNodeNames(searchNodeType: SearchNodeTypeEntity, by text: String) -> [String] {
        var nodes: [MockNode]
        
        switch searchNodeType {
        case .inShares:
            nodes = incomingNodes
        case .outShares:
            nodes = outgoingNodes
        case .publicLinks:
            nodes = publicLinksNodes
        }
        
        return nodes
            .filter {$0.name.contains(text)}
            .compactMap {$0.name}
    }
    
    private func search(type: SearchNodeTypeEntity, filteredNodeNames: [String], text: String) async throws {
        let exp = XCTestExpectation(description: "Search nodes in \(type) by '\(text)'.")
        
        let nodes = try await repo.search(type: type, text: text, sortType: .defaultAsc)
        XCTAssertNotNil(nodes)
        let nodeNames = nodes.compactMap {$0.name}
        XCTAssertEqual(nodeNames, filteredNodeNames)
        exp.fulfill()
        
        await fulfillment(of: [exp], timeout: 1.0)
    }
    
    func testSearch_incoming_nodes_shouldReturnSuccess() async throws {
        let exp = XCTestExpectation(description: "Search nodes in Incoming")
        let text = "incoming"
        let text2 = "1"
        let text3 = "not_found"
        let filteredNodes = filterNodeNames(searchNodeType: .inShares, by: text)
        let filteredNodes2 = filterNodeNames(searchNodeType: .inShares, by: text2)
        let filteredNodes3 = filterNodeNames(searchNodeType: .inShares, by: text3)
    
        try await self.search(type: .inShares, filteredNodeNames: filteredNodes, text: text)
        try await self.search(type: .inShares, filteredNodeNames: filteredNodes2, text: text2)
        try await self.search(type: .inShares, filteredNodeNames: filteredNodes3, text: text3)
        
        exp.fulfill()
        
        await fulfillment(of: [exp], timeout: 2.0)
    }
    
    func testSearch_outgoing_nodes_shouldReturnSuccess() async throws {
        let exp = XCTestExpectation(description: "Search nodes in Outgoing")
        let text = "outgoing"
        let text2 = "1"
        let text3 = "not_found"
        let filteredNodes = filterNodeNames(searchNodeType: .outShares, by: text)
        let filteredNodes2 = filterNodeNames(searchNodeType: .outShares, by: text2)
        let filteredNodes3 = filterNodeNames(searchNodeType: .outShares, by: text3)
        
        try await self.search(type: .outShares, filteredNodeNames: filteredNodes, text: text)
        try await self.search(type: .outShares, filteredNodeNames: filteredNodes2, text: text2)
        try await self.search(type: .outShares, filteredNodeNames: filteredNodes3, text: text3)
        
        exp.fulfill()
        
        await fulfillment(of: [exp], timeout: 2.0)
    }
    
    func testSearch_public_links_shouldReturnSuccess() async throws {
        let exp = XCTestExpectation(description: "Search nodes in Public Links")
        let text = "link"
        let text2 = "1"
        let text3 = "not_found"
        let filteredNodes = filterNodeNames(searchNodeType: .publicLinks, by: text)
        let filteredNodes2 = filterNodeNames(searchNodeType: .publicLinks, by: text2)
        let filteredNodes3 = filterNodeNames(searchNodeType: .publicLinks, by: text3)
        
        try await self.search(type: .publicLinks, filteredNodeNames: filteredNodes, text: text)
        try await self.search(type: .publicLinks, filteredNodeNames: filteredNodes2, text: text2)
        try await self.search(type: .publicLinks, filteredNodeNames: filteredNodes3, text: text3)
        
        exp.fulfill()
        
        await fulfillment(of: [exp], timeout: 2.0)
    }
}
