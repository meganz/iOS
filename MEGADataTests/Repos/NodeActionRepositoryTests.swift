import XCTest
@testable import MEGA

final class NodeRepositoryTests: XCTestCase {
    
    func testSlideShow_withFolderContainsImageNode_shouldReturnNodes() throws {
        let mockNode = MockNode(handle: 1, name: "TestFolder", nodeType: .folder, parentHandle: 0)
        let repo = NodeRepository(sdk: MockSdk(nodes: sampleNodesWithImages()), sharedFolderSdk: MEGASdk(), chatSdk: MEGAChatSdk())
        let images = repo.images(for: mockNode.toNodeEntity())
        
        XCTAssertTrue(images.count == 1)
    }
    
    func testSlideShow_withFolderNotContainsImageNode_shouldReturnEmpty() throws {
        let mockNode = MockNode(handle: 1, name: "TestFolder", nodeType: .folder, parentHandle: 0)
        let repo = NodeRepository(sdk: MockSdk(nodes: sampleNodesWithoutImages()), sharedFolderSdk: MEGASdk(), chatSdk: MEGAChatSdk())
        let images = repo.images(for: mockNode.toNodeEntity())
        
        XCTAssertTrue(images.count == 0)
    }
    
    func testSlideShow_withFolderHandleContainsImageNode_shouldReturnNodes() throws {
        let repo = NodeRepository(sdk: MockSdk(nodes: sampleNodesWithImages()), sharedFolderSdk: MEGASdk(), chatSdk: MEGAChatSdk())
        let images = repo.images(for: 1)
        
        XCTAssertTrue(images.count == 1)
    }
    
    func testSlideShow_withFolderHandleNotContainsImageNode_shouldReturnEmpty() throws {
        let repo = NodeRepository(sdk: MockSdk(nodes: sampleNodesWithoutImages()), sharedFolderSdk: MEGASdk(), chatSdk: MEGAChatSdk())
        let images = repo.images(for: 1)
        
        XCTAssertTrue(images.count == 0)
    }
    
    private func sampleNodesWithImages() -> [MockNode] {
        let node1 = MockNode(handle: 1, name: "TestFolder", nodeType: .folder, parentHandle: 0)
        let node2 = MockNode(handle: 2, name: "TestImage.png", nodeType: .file, parentHandle: 1)
        
        return [node1, node2]
    }
    
    private func sampleNodesWithoutImages() -> [MockNode] {
        let node1 = MockNode(handle: 1, name: "TestFolder", nodeType: .folder, parentHandle: 0)
        let node2 = MockNode(handle: 2, name: "TestVideo1.mp4", nodeType: .file, parentHandle: 1)
        
        return [node1, node2]
    }
}
