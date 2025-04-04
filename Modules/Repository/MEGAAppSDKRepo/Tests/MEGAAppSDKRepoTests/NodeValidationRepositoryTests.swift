import MEGAAppSDKRepo
import MEGAAppSDKRepoMock
import MEGADomain
import XCTest

final class NodeValidationRepositoryTests: XCTestCase {

    func testHasVersions_whenNodeExists_shouldReturnSDKValue() {
        let childNode = MockNode(handle: 3, parentHandle: 2)
        
        let sut = sut(sdk: MockSdk(
            nodes: [childNode],
            hasVersionsForNode: true
        ))
        
        XCTAssertTrue(sut.hasVersions(nodeHandle: childNode.handle))
    }
    
    func testHasVersions_whenNodeNotExists_shouldReturnFalse() {
        let sut = sut(sdk: MockSdk(
            hasVersionsForNode: true
        ))
        
        XCTAssertFalse(sut.hasVersions(nodeHandle: 1))
    }
    
    func testIsDownloaded_whenNodeExists_shouldReturnOfflineStoreValue() {
        let childNode = MockNode(handle: 3, parentHandle: 2)
        
        let sut = sut(
            sdk: MockSdk(
                nodes: [childNode],
                hasVersionsForNode: true),
            offlineStore: MockOfflineStoreBridge(
                isDownloadedForNodes: [childNode.handle: true]))
        
        XCTAssertTrue(sut.isDownloaded(nodeHandle: childNode.handle))
    }
    
    func testIsDownloaded_whenNodeNotExists_shouldReturnFalse() {
        let childNode = MockNode(handle: 3, parentHandle: 2)
        let sut = sut(
            sdk: MockSdk(
                nodes: [childNode],
                hasVersionsForNode: true),
            offlineStore: MockOfflineStoreBridge(
                isDownloadedForNodes: [childNode.handle: true]))
        
        XCTAssertFalse(sut.isDownloaded(nodeHandle: 1))
    }
    
    func testIsInRubbishBin_whenNodeExists_shouldReturnSDKValue() {
        let childNode = MockNode(handle: 3, parentHandle: 2)
        
        let sut = sut(
            sdk: MockSdk(
                nodes: [childNode],
                rubbishNodes: [childNode]))
        
        XCTAssertTrue(sut.isInRubbishBin(nodeHandle: childNode.handle))
    }
    
    func testIsInRubbishBin_whenNodeNotExists_shouldReturnFalse() {
        let childNode = MockNode(handle: 3, parentHandle: 2)
        let sut = sut(
            sdk: MockSdk(
                nodes: [childNode],
                rubbishNodes: [childNode]))
        
        XCTAssertFalse(sut.isInRubbishBin(nodeHandle: 1))
    }
    
    func testIsFileNode_whenNodeExists_shouldReturnSDKValue() {
        let childNode = MockNode(handle: 3, nodeType: .file, parentHandle: 2)
        
        let sut = sut(
            sdk: MockSdk(
                nodes: [childNode]))
        
        XCTAssertTrue(sut.isFileNode(handle: childNode.handle))
    }
    
    func testIsFileNode_whenNodeNotExists_shouldReturnFalse() {
        let childNode = MockNode(handle: 3, parentHandle: 2)
        let sut = sut(
            sdk: MockSdk(
                nodes: [childNode],
                rubbishNodes: [childNode]),
            offlineStore: MockOfflineStoreBridge(
                isDownloadedForNodes: [childNode.handle: true]))
        
        XCTAssertFalse(sut.isFileNode(handle: 1))
    }
    
    func test_isNode_desdendantOf_ancestor() async {
        let grandParentNode = MockNode(handle: 1)
        let parentNode = MockNode(handle: 2, parentHandle: 1)
        let childNode = MockNode(handle: 3, parentHandle: 2)
        
        let repo = sut(sdk: MockSdk(nodes: [grandParentNode, parentNode, childNode]))
        
        let isChildDescendantOfGrandParent = await repo.isNode(childNode.toNodeEntity(), descendantOf: grandParentNode.toNodeEntity())
        XCTAssertTrue(isChildDescendantOfGrandParent)
        
        let isChildDescendantOfParent = await repo.isNode(childNode.toNodeEntity(), descendantOf: parentNode.toNodeEntity())
        XCTAssertTrue(isChildDescendantOfParent)
        
        let isParentDescendantOfChild = await repo.isNode(parentNode.toNodeEntity(), descendantOf: childNode.toNodeEntity())
        XCTAssertFalse(isParentDescendantOfChild)
        
        let isGrandParentDescendantOfParent = await repo.isNode(grandParentNode.toNodeEntity(), descendantOf: parentNode.toNodeEntity())
        XCTAssertFalse(isGrandParentDescendantOfParent)
        
        let isGrandParentDescendantOfChild = await repo.isNode(grandParentNode.toNodeEntity(), descendantOf: childNode.toNodeEntity())
        XCTAssertFalse(isGrandParentDescendantOfChild)
    }
}

extension NodeValidationRepositoryTests {
    func sut(sdk: MockSdk = MockSdk(),
             offlineStore: MockOfflineStoreBridge = MockOfflineStoreBridge()) -> NodeValidationRepository {
        .init(sdk: sdk, offlineStore: offlineStore)
    }
}
