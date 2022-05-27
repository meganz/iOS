import XCTest
@testable import MEGA

final class MEGANode_FilePaths_Tests: XCTestCase {
    
    func testFilePath_withGreaterThanDelimeter() throws {
        let nodes = sampleNodes()
        let sdk = MockSDK(withNodes: nodes)
        let leafNode = try XCTUnwrap(nodes.last)
        
        let path = leafNode.filePath(delimeter: " > ", sdk: sdk, includeRootFolderName: true, excludeFileName: false)
        XCTAssertEqual(path.components(separatedBy: ">").count, 5)
    }
    
    func testFilePath_withForwardSlashDelimeter() throws {
        let nodes = sampleNodes()
        let sdk = MockSDK(withNodes: nodes)
        let leafNode = try XCTUnwrap(nodes.last)

        let path = leafNode.filePath(delimeter: " / ", sdk: sdk, includeRootFolderName: true, excludeFileName: false)
        XCTAssertEqual(path.components(separatedBy: "/").count, 5)
    }
    
    func testFilePath_includingRootFolderNameAndIncludingFileName() throws {
        let nodes = sampleNodes()
        let sdk = MockSDK(withNodes: nodes)
        let leafNode = try XCTUnwrap(nodes.last)

        let path = leafNode.filePath(delimeter: " > ", sdk: sdk, includeRootFolderName: true, excludeFileName: false)
        XCTAssertEqual(path, "Test1 > Test2 > Test3 > Test4 > Test5")
    }
    
    func testFilePath_excludingRootFolderNameAndIncludingFileName() throws {
        let nodes = sampleNodes()
        let sdk = MockSDK(withNodes: nodes)
        let leafNode = try XCTUnwrap(nodes.last)

        let path = leafNode.filePath(delimeter: " > ", sdk: sdk, includeRootFolderName: false, excludeFileName: false)
        XCTAssertEqual(path, "Test2 > Test3 > Test4 > Test5")
    }
    
    func testFilePath_includingRootFolderNameAndExcludingFileName() throws {
        let nodes = sampleNodes()
        let sdk = MockSDK(withNodes: nodes)
        let leafNode = try XCTUnwrap(nodes.last)

        let path = leafNode.filePath(delimeter: " > ", sdk: sdk, includeRootFolderName: true, excludeFileName: true)
        XCTAssertEqual(path, "Test1 > Test2 > Test3 > Test4")
    }
    
    func testFilePath_excludingRootFolderNameAndExcludingFileName() throws {
        let nodes = sampleNodes()
        let sdk = MockSDK(withNodes: nodes)
        let leafNode = try XCTUnwrap(nodes.last)

        let path = leafNode.filePath(delimeter: " > ", sdk: sdk, includeRootFolderName: false, excludeFileName: true)
        XCTAssertEqual(path, "Test2 > Test3 > Test4")
    }
    
    func testFilePath_withNoParentFolderInlcudingRootFolderNameAndIncludingFileName() {
        let node = MockNode(name: "Test1", handle: 1, parentHandle: 0)
        let sdk = MockSDK(withNodes: [node])
        
        let path = node.filePath(delimeter: " > ", sdk: sdk, includeRootFolderName: true, excludeFileName: false)
        XCTAssertEqual(path, "Test1")
    }
    
    func testFilePath_withNoParentFolderExcludingRootFolderNameAndExcludingFileName() {
        let node = MockNode(name: "Test1", handle: 1, parentHandle: 0)
        let sdk = MockSDK(withNodes: [node])
        
        let path = node.filePath(delimeter: " > ", sdk: sdk, includeRootFolderName: false, excludeFileName: true)
        XCTAssertEqual(path, "")
    }
    
    func testFilePath_withNoParentFolderIncludingRootFolderNameAndExcludingFileName() {
        let node = MockNode(name: "Test1", handle: 1, parentHandle: 0)
        let sdk = MockSDK(withNodes: [node])
        
        let path = node.filePath(delimeter: " > ", sdk: sdk, includeRootFolderName: true, excludeFileName: true)
        XCTAssertEqual(path, "")
    }
    
    func testFilePath_withNoParentFolderExcludingRootFolderNameAndIncludingFileName() {
        let node = MockNode(name: "Test1", handle: 1, parentHandle: 0)
        let sdk = MockSDK(withNodes: [node])
        
        let path = node.filePath(delimeter: " > ", sdk: sdk, includeRootFolderName: true, excludeFileName: true)
        XCTAssertEqual(path, "")
    }
    
    private func sampleNodes() -> [MockNode] {
        let node1 = MockNode(name: "Test1", handle: 1, parentHandle: 0)
        let node2 = MockNode(name: "Test2", handle: 2, parentHandle: 1)
        let node3 = MockNode(name: "Test3", handle: 3, parentHandle: 2)
        let node4 = MockNode(name: "Test4", handle: 4, parentHandle: 3)
        let node5 = MockNode(name: "Test5", handle: 5, parentHandle: 4)
        return [node1, node2, node3, node4, node5]
    }
}


final fileprivate class MockSDK: MEGASdk {
    private let nodes: [MockNode]
    
    init(withNodes nodes: [MockNode]) {
        self.nodes = nodes
        super.init()
    }
    
    override func parentNode(for node: MEGANode) -> MEGANode? {
        guard let inputNode = node as? MockNode else {
            return nil
        }
        
        return nodes.filter({ $0._handle == inputNode._parentHandle }).first
    }
}

final fileprivate class MockNode: MEGANode {
    private let _name: String
    let _handle: MEGAHandle
    let _parentHandle: MEGAHandle
    
    override var name: String! {
        _name
    }
    
    init(name: String, handle: MEGAHandle, parentHandle: MEGAHandle) {
        _name = name
        _handle = handle
        _parentHandle = parentHandle
        super.init()
    }
}
