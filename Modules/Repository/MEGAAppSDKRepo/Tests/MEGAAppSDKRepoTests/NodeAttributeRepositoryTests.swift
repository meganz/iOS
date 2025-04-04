import MEGAAppSDKRepo
import MEGAAppSDKRepoMock
import MEGADomain
import XCTest

final class NodeAttributeRepositoryTests: XCTestCase {

    func testPathForNode() {
        let path = "/test/path"
        let mockNode = MockNode(handle: 1, nodePath: path)
        let mockSdk = MockSdk(nodes: [mockNode])
        let sut = NodeAttributeRepository(sdk: mockSdk)
        let node = NodeEntity(handle: 1)
        XCTAssertEqual(path, sut.pathFor(node: node))
    }
    
    func testNumberChildrenForNode() {
        let mockNode = MockNode(handle: 1)
        let mockNode2 = MockNode(handle: 2, parentHandle: 1)
        let mockNode3 = MockNode(handle: 3, parentHandle: 1)
        let mockSdk = MockSdk(nodes: [mockNode, mockNode2, mockNode3])
        let sut = NodeAttributeRepository(sdk: mockSdk)
        let node = NodeEntity(handle: 1)
        XCTAssertEqual(2, sut.numberChildrenFor(node: node))
    }
    
    func testIsInRubbishBin_shouldReturnTrue() {
        let mockNode = MockNode(handle: 1)
        let mockSdk = MockSdk(nodes: [mockNode], rubbishNodes: [mockNode])
        let sut = NodeAttributeRepository(sdk: mockSdk)
        let node = NodeEntity(handle: 1)
        XCTAssertTrue(sut.isInRubbishBin(node: node))
    }
    
    func testIsInRubbishBin_shouldReturnFalse() {
        let mockNode = MockNode(handle: 1)
        let mockSdk = MockSdk(nodes: [mockNode])
        let sut = NodeAttributeRepository(sdk: mockSdk)
        let node = NodeEntity(handle: 1)
        XCTAssertFalse(sut.isInRubbishBin(node: node))
    }
}
