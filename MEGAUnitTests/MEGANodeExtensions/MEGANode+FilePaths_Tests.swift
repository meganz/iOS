import XCTest
@testable import MEGA

class MEGANode_FilePaths_Tests: XCTestCase {

    func testFilePath_withGreaterThanDelimeter() {
        let nodes = sampleNodes()
        let sdk = testSDK(withNodes: nodes)
        
        let path = nodes.last!.filePath(withDelimeter: " > ", sdk: sdk, includeRootFolderName: true, excludeFileName: false)
        XCTAssertEqual(path.components(separatedBy: ">").count, 5)
    }
    
    func testFilePath_withForwardSlashDelimeter() {
        let nodes = sampleNodes()
        let sdk = testSDK(withNodes: nodes)
        
        let path = nodes.last!.filePath(withDelimeter: " / ", sdk: sdk, includeRootFolderName: true, excludeFileName: false)
        XCTAssertEqual(path.components(separatedBy: "/").count, 5)
    }
    
    func testFilePath_includingRootFolderNameAndIncludingFileName() {
        let nodes = sampleNodes()
        let sdk = testSDK(withNodes: nodes)
        
        let path = nodes.last!.filePath(withDelimeter: " > ", sdk: sdk, includeRootFolderName: true, excludeFileName: false)
        XCTAssertEqual(path, "Test1 > Test2 > Test3 > Test4 > Test5")
    }
    
    func testFilePath_excludingRootFolderNameAndIncludingFileName() {
        let nodes = sampleNodes()
        let sdk = testSDK(withNodes: nodes)
        
        let path = nodes.last!.filePath(withDelimeter: " > ", sdk: sdk, includeRootFolderName: false, excludeFileName: false)
        XCTAssertEqual(path, "Test2 > Test3 > Test4 > Test5")
    }
    
    func testFilePath_includingRootFolderNameAndExcludingFileName() {
        let nodes = sampleNodes()
        let sdk = testSDK(withNodes: nodes)
        
        let path = nodes.last!.filePath(withDelimeter: " > ", sdk: sdk, includeRootFolderName: true, excludeFileName: true)
        XCTAssertEqual(path, "Test1 > Test2 > Test3 > Test4")
    }
    
    func testFilePath_excludingRootFolderNameAndExcludingFileName() {
        let nodes = sampleNodes()
        let sdk = testSDK(withNodes: nodes)
        
        let path = nodes.last!.filePath(withDelimeter: " > ", sdk: sdk, includeRootFolderName: false, excludeFileName: true)
        XCTAssertEqual(path, "Test2 > Test3 > Test4")
    }
    
    func testFilePath_withNoParentFolderInlcudingRootFolderNameAndIncludingFileName() {
        let node = Node(name: "Test1", handle: 1, parentHandle: -1)
        let sdk = testSDK(withNodes: [node])
        
        let path = node.filePath(withDelimeter: " > ", sdk: sdk, includeRootFolderName: true, excludeFileName: false)
        XCTAssertEqual(path, "Test1")
    }
    
    func testFilePath_withNoParentFolderExcludingRootFolderNameAndExcludingFileName() {
        let node = Node(name: "Test1", handle: 1, parentHandle: -1)
        let sdk = testSDK(withNodes: [node])
        
        let path = node.filePath(withDelimeter: " > ", sdk: sdk, includeRootFolderName: false, excludeFileName: true)
        XCTAssertEqual(path, "")
    }
    
    func testFilePath_withNoParentFolderIncludingRootFolderNameAndExcludingFileName() {
        let node = Node(name: "Test1", handle: 1, parentHandle: -1)
        let sdk = testSDK(withNodes: [node])
        
        let path = node.filePath(withDelimeter: " > ", sdk: sdk, includeRootFolderName: true, excludeFileName: true)
        XCTAssertEqual(path, "")
    }
    
    func testFilePath_withNoParentFolderExcludingRootFolderNameAndIncludingFileName() {
        let node = Node(name: "Test1", handle: 1, parentHandle: -1)
        let sdk = testSDK(withNodes: [node])
        
        let path = node.filePath(withDelimeter: " > ", sdk: sdk, includeRootFolderName: true, excludeFileName: true)
        XCTAssertEqual(path, "")
    }
    
    private func sampleNodes() -> [Node] {
        let node1 = Node(name: "Test1", handle: 1, parentHandle: -1)
        let node2 = Node(name: "Test2", handle: 2, parentHandle: 1)
        let node3 = Node(name: "Test3", handle: 3, parentHandle: 2)
        let node4 = Node(name: "Test4", handle: 4, parentHandle: 3)
        let node5 = Node(name: "Test5", handle: 5, parentHandle: 4)
        return [node1, node2, node3, node4, node5]
    }
    
    private func testSDK(withNodes nodes: [Node]) -> TestSDK {
        let testSDK = TestSDK()
        testSDK.nodes = nodes
        return testSDK
    }

}


class TestSDK: MEGASdk {
    var nodes: [Node] = []
    
    override func parentNode(for node: MEGANode) -> MEGANode? {
        guard let inputNode = node as? Node else {
            return nil
        }
        
        return nodes.filter({ $0._handle == inputNode._parentHandle }).first
    }
}

class Node: MEGANode {
    let _name: String
    let _handle: Int
    let _parentHandle: Int
    
    override var name: String! {
        return  _name
    }
    
    init(name: String, handle: Int, parentHandle: Int) {
        _name = name
        _handle = handle
        _parentHandle = parentHandle
        super.init()
    }
}
