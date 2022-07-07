import XCTest
@testable import MEGA

final class NodeRepositoryTests: XCTestCase {
    
    func testSlideShow_withFolderContainsImageNode_shouldReturnNodes() throws {
        let mockNode = MockNodeWithTypeAndParent(name: "TestFolder", nodeType: .folder, handle: 1, parentHandle: 0)
        let repo = NodeRepository(sdk: MockSDK(nodes: sampleNodesWithImages()), sharedFolderSdk: MEGASdk(), chatSdk: MEGAChatSdk())
        let images = repo.images(for: mockNode.toNodeEntity())
        
        XCTAssertTrue(images.count == 1)
    }
    
    func testSlideShow_withFolderNotContainsImageNode_shouldReturnEmpty() throws {
        let mockNode = MockNodeWithTypeAndParent(name: "TestFolder", nodeType: .folder, handle: 1, parentHandle: 0)
        let repo = NodeRepository(sdk: MockSDK(nodes: sampleNodesWithoutImages()), sharedFolderSdk: MEGASdk(), chatSdk: MEGAChatSdk())
        let images = repo.images(for: mockNode.toNodeEntity())
        
        XCTAssertTrue(images.count == 0)
    }
    
    func testSlideShow_withFolderHandleContainsImageNode_shouldReturnNodes() throws {
        let repo = NodeRepository(sdk: MockSDK(nodes: sampleNodesWithImages()), sharedFolderSdk: MEGASdk(), chatSdk: MEGAChatSdk())
        let images = repo.images(for: 1)
        
        XCTAssertTrue(images.count == 1)
    }
    
    func testSlideShow_withFolderHandleNotContainsImageNode_shouldReturnEmpty() throws {
        let repo = NodeRepository(sdk: MockSDK(nodes: sampleNodesWithoutImages()), sharedFolderSdk: MEGASdk(), chatSdk: MEGAChatSdk())
        let images = repo.images(for: 1)
        
        XCTAssertTrue(images.count == 0)
    }
    
    private func sampleNodesWithImages() -> [MockNodeWithTypeAndParent] {
        let node1 = MockNodeWithTypeAndParent(name: "TestFolder", nodeType: .folder, handle: 1, parentHandle: 0)
        let node2 = MockNodeWithTypeAndParent(name: "TestImage.png", nodeType: .image, handle: 2, parentHandle: 1)
        
        return [node1, node2]
    }
    
    private func sampleNodesWithoutImages() -> [MockNodeWithTypeAndParent] {
        let node1 = MockNodeWithTypeAndParent(name: "TestFolder", nodeType: .folder, handle: 1, parentHandle: 0)
        let node2 = MockNodeWithTypeAndParent(name: "TestVideo1.mp4", nodeType: .image, handle: 2, parentHandle: 1)
        
        return [node1, node2]
    }
}

final fileprivate class MockNodeList: MEGANodeList {
    private let nodes: [MEGANode]
    
    init(nodes: [MEGANode] = []) {
        self.nodes = nodes
        super.init()
    }
    
    override var size: NSNumber! {
        NSNumber(integerLiteral: nodes.count)
    }
    
    override func node(at index: Int) -> MEGANode! {
        nodes[index]
    }
}

final fileprivate class MockSDK: MEGASdk {
    private let nodes: [MEGANode]
    
    init(nodes: [MEGANode]) {
        self.nodes = nodes
        super.init()
    }
    
    override func parentNode(for node: MEGANode) -> MEGANode? {
        nodes.filter({ $0.handle == node.parentHandle }).first
    }
    
    override func children(forParent parent: MEGANode) -> MEGANodeList {
        let children = nodes.filter({ $0.handle != parent.handle })
        
        return MockNodeList(nodes: children)
    }
    
    override func node(forHandle handle: UInt64) -> MEGANode? {
        nodes.filter({ $0.handle == handle }).first
    }
}
