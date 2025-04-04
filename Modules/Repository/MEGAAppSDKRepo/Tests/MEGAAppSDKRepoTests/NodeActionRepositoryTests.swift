import MEGAAppSDKRepo
import MEGAAppSDKRepoMock
import MEGADomain
import MEGASdk
import XCTest

final class NodeActionRepositoryTests: XCTestCase {
    func testRemoveLink() async throws {
        let node = MockNode(handle: 1, isNodeExported: true)
        let sdk = MockSdk(nodes: [node])
        let sut = makeSUT(sdk: sdk)
        
        let nodeBeforeRemoveLink = try XCTUnwrap(sdk.node(forHandle: HandleEntity(1)))
        XCTAssertTrue(nodeBeforeRemoveLink.isExported())
       
        try await sut.removeLink(nodes: [nodeBeforeRemoveLink.toNodeEntity()])
        
        let nodeAfterRemoveLink = try XCTUnwrap(sdk.node(forHandle: HandleEntity(1)))
        XCTAssertFalse(nodeAfterRemoveLink.isExported())
    }
    
    func testSetSensitive_called_shouldSetSensitiveToCorrectState() async throws {
        let result = try await withThrowingTaskGroup(of: Bool.self) { group in
            [true, false].forEach { sensitive in
                let node = MockNode(handle: 7, isMarkedSensitive: sensitive)
                let sdk = MockSdk(nodes: [node])
                let sut = self.makeSUT(sdk: sdk)
                
                group.addTask { @Sendable in
                    let result = try await sut.setSensitive(node: node.toNodeEntity(),
                                                            sensitive: sensitive)
                    
                    XCTAssertEqual(result, node.toNodeEntity())
                    return try XCTUnwrap(sdk.isNodeSensitive) == sensitive
                }
            }
            
            return try await group.allSatisfy { $0 }
        }
        XCTAssertTrue(result)
    }
    
    func testSetSensitive_nodeNotFound_shouldThrowNodeNotFoundError() async throws {
        let node = MockNode(handle: 7, isMarkedSensitive: true)
        let sut = makeSUT()
        
        do {
            _ = try await sut.setSensitive(node: node.toNodeEntity(),
                                           sensitive: true)
            XCTFail("Should have thrown error")
        } catch let error as NodeErrorEntity {
            XCTAssertEqual(error, .nodeNotFound)
        } catch {
            XCTFail("Invalid exception caught")
        }
    }
    
    func testHideNode_markSensitiveFail_shouldThrowGenericError() async throws {
        let node = MockNode(handle: 7, isMarkedSensitive: true)
        let sdk = MockSdk(nodes: [node], megaSetError: .apiEFailed)
        
        let sut = makeSUT(sdk: sdk)
        do {
            _ = try await sut.setSensitive(node: node.toNodeEntity(),
                                           sensitive: true)
            XCTFail("Should have thrown error")
        } catch let error as GenericErrorEntity {
            XCTAssertNotNil(error)
        } catch {
            XCTFail("Invalid exception caught")
        }
    }
    
    // MARK: - Private
    
    private func makeSUT(sdk: MEGASdk = MockSdk()) -> NodeActionRepository {
        NodeActionRepository(sdk: sdk)
    }
}
