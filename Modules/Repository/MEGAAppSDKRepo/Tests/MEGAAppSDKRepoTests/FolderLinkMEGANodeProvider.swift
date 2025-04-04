import MEGAAppSDKRepo
import MEGAAppSDKRepoMock
import MEGADomain
import XCTest

final class FolderLinkMEGANodeProviderTest: XCTestCase {
    
    func testNodeForHandle_onNodeRetrieved_shouldReturnAuthorizedNode() async {
        let hande = HandleEntity(5)
        let expectedNode = MockNode(handle: hande)
        let sdk = MockSdk(nodes: [expectedNode])
        
        let sut = FolderLinkMEGANodeProvider(sdk: sdk)
        let node = await sut.node(for: hande)
        XCTAssertEqual(node, expectedNode)
        XCTAssertEqual(sdk.authorizeNodeCalled, 1)
    }
    
    func testNodeForHandle_onNodeNotRetrieved_shouldReturnNil() async {
        let sut = FolderLinkMEGANodeProvider(sdk: MockSdk(nodes: []))
                                          
        let node = await sut.node(for: HandleEntity(6))
                                        
        XCTAssertNil(node)
    }
}
