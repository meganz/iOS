import MEGAAppSDKRepo
import MEGAAppSDKRepoMock
import MEGADomain
import XCTest

final class DefaultMEGANodeProviderTests: XCTestCase {

    func testNodeForHandle_onNodeRetrieved_shouldReturnNode() async {
        let hande = HandleEntity(5)
        let expectedNode = MockNode(handle: hande)
        let sdk = MockSdk(nodes: [expectedNode])
        
        let sut = DefaultMEGANodeProvider(sdk: sdk)
        let node = await sut.node(for: hande)
        XCTAssertEqual(node, expectedNode)
    }
    
    func testNodeForHandle_onNodeNotRetrieved_shouldReturnNil() async {
        let sut = DefaultMEGANodeProvider(sdk: MockSdk(nodes: []))
                                          
        let node = await sut.node(for: HandleEntity(6))
                                          
        XCTAssertNil(node)
    }
}
