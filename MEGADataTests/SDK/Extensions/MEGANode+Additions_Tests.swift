@testable import MEGA
import MEGAAppSDKRepoMock
import XCTest

final class MEGANode_Additions_Tests: XCTestCase {
    
    func testMegaNodeArrayExtension_withEmptyArray() {
        let nodes: [MEGANode] = []
        let counts = nodes.contentCounts()
        XCTAssertTrue(counts.fileCount == 0 && counts.folderCount == 0)
    }
    
    func testMegaNodeArrayExtension_withAllFileNodesInArray() {
        let nodes: [MEGANode] = (0...10).map { MockNode(handle: $0) }
        let counts = nodes.contentCounts()
        XCTAssertTrue(counts.fileCount == 11 && counts.folderCount == 0)
    }
    
    func testMegaNodeArrayExtension_withAllFolderNodesInArray() {
        let nodes: [MEGANode] = (0...10).map { MockNode(handle: $0, nodeType: .folder) }
        let counts = nodes.contentCounts()
        XCTAssertTrue(counts.fileCount == 0 && counts.folderCount == 11)
    }
    
    func testMegaNodeArrayExtension_withEqualFileAndFolderNodesInArray() {
        var nodes: [MEGANode] = (0...10).map { MockNode(handle: $0) }
        nodes.append(contentsOf: (0...10).map { MockNode(handle: $0, nodeType: .folder) })
        let counts = nodes.contentCounts()
        XCTAssertTrue(counts.fileCount == counts.folderCount)
    }

    func testMegaNodeArrayExtension_withMoreFileNodesThanFolderNodesInArray() {
        var nodes: [MEGANode] = (0...11).map { MockNode(handle: $0) }
        nodes.append(contentsOf: (0...10).map { MockNode(handle: $0, nodeType: .folder) })
        let counts = nodes.contentCounts()
        XCTAssertTrue(counts.fileCount > counts.folderCount)
    }
    
    func testMegaNodeArrayExtension_withLessFileNodesThanFolderNodesInArray() {
        var nodes: [MEGANode] = (0...10).map { MockNode(handle: $0) }
        nodes.append(contentsOf: (0...11).map { MockNode(handle: $0, nodeType: .folder) })
        let counts = nodes.contentCounts()
        XCTAssertTrue(counts.fileCount < counts.folderCount)
    }
    
    func testIsDescendant_passingInTheSameNodeAsParameter() {
        let node = MockNode(handle: 1, parentHandle: 2)
        let sdk = MockSdk(nodes: [node])
        XCTAssertTrue(node.isDescendant(of: node, in: sdk))
    }
    
    func testIsDescendant_passingInRootNode() {
        let rootNode = MockNode(handle: 1, parentHandle: 0)
        let sampleNode = MockNode(handle: 3, parentHandle: 4)
        let sdk = MockSdk(nodes: [rootNode, sampleNode])
        XCTAssertFalse(rootNode.isDescendant(of: sampleNode, in: sdk))
    }
    
    func testIsDescendant_passingParentAsParameter() {
        let childNode = MockNode(handle: 1, parentHandle: 2)
        let parentNode = MockNode(handle: 2, parentHandle: 0)
        let sdk = MockSdk(nodes: [childNode, parentNode])
        XCTAssertTrue(childNode.isDescendant(of: parentNode, in: sdk))
    }
    
    func testIsDescendant_passingGrandParentAsParameter() {
        let childNode = MockNode(handle: 1, parentHandle: 2)
        let parentNode = MockNode(handle: 2, parentHandle: 3)
        let grandParentNode = MockNode(handle: 3, parentHandle: 0)
        let sdk = MockSdk(nodes: [childNode, parentNode, grandParentNode])
        XCTAssertTrue(childNode.isDescendant(of: grandParentNode, in: sdk))
    }
    
    func testIsDescendant_passingGreatGrandParentAsParameter() {
        let childNode = MockNode(handle: 1, parentHandle: 2)
        let parentNode = MockNode(handle: 2, parentHandle: 3)
        let grandParentNode = MockNode(handle: 3, parentHandle: 4)
        let greatGrandParentNode = MockNode(handle: 4, parentHandle: 0)
        let sdk = MockSdk(nodes: [childNode, parentNode, grandParentNode, greatGrandParentNode])
        XCTAssertTrue(childNode.isDescendant(of: greatGrandParentNode, in: sdk))
    }
    
    func testIsUndecrypted_nodeIsDecryptedTrue_ownerIsVerifiedTrue_shouldBeFalse() {
        let node = MockNode(handle: 1, isNodeDecrypted: true)
        let sdk = MockSdk(isSharedFolderOwnerVerified: true, sharedFolderOwner: MockUser(handle: 1))
        XCTAssertFalse(node.isUndecrypted(ownerEmail: "", in: sdk))
    }
    
    func testIsUndecrypted_nodeIsDecryptedFalse_ownerIsVerifiedFalse_shouldBeTrue() {
        let node = MockNode(handle: 1, isNodeDecrypted: false)
        let sdk = MockSdk(isSharedFolderOwnerVerified: false, sharedFolderOwner: MockUser(handle: 1))
        XCTAssertTrue(node.isUndecrypted(ownerEmail: "", in: sdk))
    }
    
    func testIsUndecrypted_nodeIsDecryptedTrue_ownerIsVerifiedFalse_shouldBeTrue() {
        let node = MockNode(handle: 1, isNodeDecrypted: true)
        let sdk = MockSdk(isSharedFolderOwnerVerified: false, sharedFolderOwner: MockUser(handle: 1))
        XCTAssertTrue(node.isUndecrypted(ownerEmail: "", in: sdk))
    }
}
