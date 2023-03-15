
import XCTest
import MEGADomain
@testable import MEGA

final class NodeActionRepositoryTests: XCTestCase {
    var repository: NodeActionRepository!
    var sdk: MockSdk!

    override func setUpWithError() throws {
        let node = MockNode(handle: 1, isNodeExported: true)
        sdk = MockSdk(nodes: [node])
        repository = NodeActionRepository(sdk: sdk)
    }

    func testRemoveLink() async throws {
        let nodeBeforeRemoveLink = try XCTUnwrap(sdk.node(forHandle: HandleEntity(1)))
        XCTAssertTrue(nodeBeforeRemoveLink.isExported())
       
        try await repository.removeLink(nodes: [nodeBeforeRemoveLink.toNodeEntity()])
        
        let nodeAfterRemoveLink = try XCTUnwrap(sdk.node(forHandle: HandleEntity(1)))
        XCTAssertFalse(nodeAfterRemoveLink.isExported())
    }
}
