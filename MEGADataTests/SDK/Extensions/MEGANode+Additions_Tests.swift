
import XCTest
@testable import MEGA

final class MEGANode_Additions_Tests: XCTestCase {
    
    func testMegaNodeArrayExtension_withEmptyArray() {
        let nodes: [MEGANode] = []
        let counts = nodes.contentCounts()
        XCTAssertTrue(counts.fileCount == 0 && counts.folderCount == 0)
    }
    
    func testMegaNodeArrayExtension_withAllFileNodesInArray() {
        let nodes: [MEGANode] = (0...10).map { _ in MockNode() }
        let counts = nodes.contentCounts()
        XCTAssertTrue(counts.fileCount == 11 && counts.folderCount == 0)
    }
    
    func testMegaNodeArrayExtension_withAllFolderNodesInArray() {
        let nodes: [MEGANode] = (0...10).map { _ in MockNode(nodeType: .folder) }
        let counts = nodes.contentCounts()
        XCTAssertTrue(counts.fileCount == 0 && counts.folderCount == 11)
    }
    
    func testMegaNodeArrayExtension_withEqualFileAndFolderNodesInArray() {
        var nodes: [MEGANode] = (0...10).map { _ in MockNode() }
        nodes.append(contentsOf: (0...10).map { _ in MockNode(nodeType: .folder) })
        let counts = nodes.contentCounts()
        XCTAssertTrue(counts.fileCount == counts.folderCount)
    }

    func testMegaNodeArrayExtension_withMoreFileNodesThanFolderNodesInArray() {
        var nodes: [MEGANode] = (0...11).map { _ in MockNode() }
        nodes.append(contentsOf: (0...10).map { _ in MockNode(nodeType: .folder) })
        let counts = nodes.contentCounts()
        XCTAssertTrue(counts.fileCount > counts.folderCount)
    }
    
    func testMegaNodeArrayExtension_withLessFileNodesThanFolderNodesInArray() {
        var nodes: [MEGANode] = (0...10).map { _ in MockNode() }
        nodes.append(contentsOf: (0...11).map { _ in MockNode(nodeType: .folder) })
        let counts = nodes.contentCounts()
        XCTAssertTrue(counts.fileCount < counts.folderCount)
    }
    
    func testIsDescendant_passingInTheSameNodeAsParameter() {
        let node = MockNode(handle: 1, parentHandle: 2)
        let sdk = MockSDK(nodes: [node])
        XCTAssertTrue(node.isDescendant(of: node, in: sdk))
    }
    
    func testIsDescendant_passingInRootNode() {
        let rootNode = MockNode(handle: 1, parentHandle: 0)
        let sampleNode = MockNode(handle: 3, parentHandle: 4)
        let sdk = MockSDK(nodes: [rootNode, sampleNode])
        XCTAssertFalse(rootNode.isDescendant(of: sampleNode, in: sdk))
    }
    
    func testIsDescendant_passingParentAsParameter() {
        let childNode = MockNode(handle: 1, parentHandle: 2)
        let parentNode = MockNode(handle: 2, parentHandle: 0)
        let sdk = MockSDK(nodes: [childNode, parentNode])
        XCTAssertTrue(childNode.isDescendant(of: parentNode, in: sdk))
    }
    
    func testIsDescendant_passingGrandParentAsParameter() {
        let childNode = MockNode(handle: 1, parentHandle: 2)
        let parentNode = MockNode(handle: 2, parentHandle: 3)
        let grandParentNode = MockNode(handle: 3, parentHandle: 0)
        let sdk = MockSDK(nodes: [childNode, parentNode, grandParentNode])
        XCTAssertTrue(childNode.isDescendant(of: grandParentNode, in: sdk))
    }
    
    func testIsDescendant_passingGreatGrandParentAsParameter() {
        let childNode = MockNode(handle: 1, parentHandle: 2)
        let parentNode = MockNode(handle: 2, parentHandle: 3)
        let grandParentNode = MockNode(handle: 3, parentHandle: 4)
        let greatGrandParentNode = MockNode(handle: 4, parentHandle: 0)
        let sdk = MockSDK(nodes: [childNode, parentNode, grandParentNode, greatGrandParentNode])
        XCTAssertTrue(childNode.isDescendant(of: greatGrandParentNode, in: sdk))
    }
}

final fileprivate class MockNode: MEGANode {
    enum NodeType {
        case file
        case folder
    }
    
    private let nodeType: NodeType
    private let _handle: MEGAHandle
    private let _parentHandle: MEGAHandle
    
    override var parentHandle: MEGAHandle {
        _parentHandle
    }
    
    override var handle: MEGAHandle {
        _handle
    }
    
    init(nodeType: NodeType = .file, handle: MEGAHandle = 0, parentHandle: MEGAHandle = 0) {
        self.nodeType = nodeType
        _handle = handle
        _parentHandle = parentHandle
        super.init()
    }
    
    override func isFile() -> Bool {
        nodeType == .file
    }
    
    override func isFolder() -> Bool {
        nodeType == .folder
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
}
