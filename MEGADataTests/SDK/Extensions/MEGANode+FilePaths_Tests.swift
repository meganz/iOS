@testable import MEGA
import MEGAAppSDKRepoMock
import XCTest

final class MEGANode_FilePaths_Tests: XCTestCase {
    
    func testFilePath_withGreaterThanDelimeter() throws {
        let nodes = sampleNodes()
        let sdk = MockSdk(nodes: nodes)
        let leafNode = try XCTUnwrap(nodes.last)
        
        let path = leafNode.filePath(delimeter: " > ", sdk: sdk, includeRootFolderName: true, excludeFileName: false)
        XCTAssertEqual(path.components(separatedBy: ">").count, 5)
    }
    
    func testFilePath_withForwardSlashDelimeter() throws {
        let nodes = sampleNodes()
        let sdk = MockSdk(nodes: nodes)
        let leafNode = try XCTUnwrap(nodes.last)

        let path = leafNode.filePath(delimeter: " / ", sdk: sdk, includeRootFolderName: true, excludeFileName: false)
        XCTAssertEqual(path.components(separatedBy: "/").count, 5)
    }
    
    func testFilePath_includingRootFolderNameAndIncludingFileName() throws {
        let nodes = sampleNodes()
        let sdk = MockSdk(nodes: nodes)
        let leafNode = try XCTUnwrap(nodes.last)

        let path = leafNode.filePath(delimeter: " > ", sdk: sdk, includeRootFolderName: true, excludeFileName: false)
        XCTAssertEqual(path, "Test1 > Test2 > Test3 > Test4 > Test5")
    }
    
    func testFilePath_excludingRootFolderNameAndIncludingFileName() throws {
        let nodes = sampleNodes()
        let sdk = MockSdk(nodes: nodes)
        let leafNode = try XCTUnwrap(nodes.last)

        let path = leafNode.filePath(delimeter: " > ", sdk: sdk, includeRootFolderName: false, excludeFileName: false)
        XCTAssertEqual(path, "Test2 > Test3 > Test4 > Test5")
    }
    
    func testFilePath_includingRootFolderNameAndExcludingFileName() throws {
        let nodes = sampleNodes()
        let sdk = MockSdk(nodes: nodes)
        let leafNode = try XCTUnwrap(nodes.last)

        let path = leafNode.filePath(delimeter: " > ", sdk: sdk, includeRootFolderName: true, excludeFileName: true)
        XCTAssertEqual(path, "Test1 > Test2 > Test3 > Test4")
    }
    
    func testFilePath_excludingRootFolderNameAndExcludingFileName() throws {
        let nodes = sampleNodes()
        let sdk = MockSdk(nodes: nodes)
        let leafNode = try XCTUnwrap(nodes.last)

        let path = leafNode.filePath(delimeter: " > ", sdk: sdk, includeRootFolderName: false, excludeFileName: true)
        XCTAssertEqual(path, "Test2 > Test3 > Test4")
    }
    
    func testFilePath_withNoParentFolderInlcudingRootFolderNameAndIncludingFileName() {
        let node = MockNode(handle: 1, name: "Test1", parentHandle: 0)
        let sdk = MockSdk(nodes: [node])
        
        let path = node.filePath(delimeter: " > ", sdk: sdk, includeRootFolderName: true, excludeFileName: false)
        XCTAssertEqual(path, "Test1")
    }
    
    func testFilePath_withNoParentFolderExcludingRootFolderNameAndExcludingFileName() {
        let node = MockNode(handle: 1, name: "Test1", parentHandle: 0)
        let sdk = MockSdk(nodes: [node])
        
        let path = node.filePath(delimeter: " > ", sdk: sdk, includeRootFolderName: false, excludeFileName: true)
        XCTAssertEqual(path, "")
    }
    
    func testFilePath_withNoParentFolderIncludingRootFolderNameAndExcludingFileName() {
        let node = MockNode(handle: 1, name: "Test1", parentHandle: 0)
        let sdk = MockSdk(nodes: [node])
        
        let path = node.filePath(delimeter: " > ", sdk: sdk, includeRootFolderName: true, excludeFileName: true)
        XCTAssertEqual(path, "")
    }
    
    func testFilePath_withNoParentFolderExcludingRootFolderNameAndIncludingFileName() {
        let node = MockNode(handle: 1, name: "Test1", parentHandle: 0)
        let sdk = MockSdk(nodes: [node])
        
        let path = node.filePath(delimeter: " > ", sdk: sdk, includeRootFolderName: true, excludeFileName: true)
        XCTAssertEqual(path, "")
    }
    
    private func sampleNodes() -> [MockNode] {
        let node1 = MockNode(handle: 1, name: "Test1", parentHandle: 0)
        let node2 = MockNode(handle: 2, name: "Test2", parentHandle: 1)
        let node3 = MockNode(handle: 3, name: "Test3", parentHandle: 2)
        let node4 = MockNode(handle: 4, name: "Test4", parentHandle: 3)
        let node5 = MockNode(handle: 5, name: "Test5", parentHandle: 4)
        return [node1, node2, node3, node4, node5]
    }
}
