import MEGAAppSDKRepo
import MEGAAppSDKRepoMock
import MEGADomain
import XCTest

final class NodeActionsRepositoryTests: XCTestCase {
    
    // MARK: - Copy node with same fingerprint
    func testCopyNodeIfExistsWithSameFingerprint_withNewName_shouldCopyWithNewNameAndReturnTrue() {
        let parentHandle: HandleEntity = 1
        let mockSdk = mockSdk(nodeHandle: 2, toParentHandle: parentHandle, nodeFingerprint: "Fingerprint 0")
        
        let sut = makeSUT(sdk: mockSdk)
        let isCopySuccess = sut.copyNodeIfExistsWithSameFingerprint(
            at: "fingerprintPath",
            parentHandle: parentHandle,
            newName: "File node 1"
        )
        
        XCTAssertTrue(isCopySuccess)
        XCTAssertEqual(mockSdk.copyNodeWithNewNameCallCount, 1)
    }
    
    func testCopyNodeIfExistsWithSameFingerprint_withSameName_shouldCopyWithSameNameAndReturnTrue() {
        let parentHandle: HandleEntity = 1
        let mockSdk = mockSdk(nodeHandle: 2, toParentHandle: parentHandle, nodeFingerprint: "Fingerprint 0")
        
        let sut = makeSUT(sdk: mockSdk)
        let isCopySuccess = sut.copyNodeIfExistsWithSameFingerprint(
            at: "fingerprintPath",
            parentHandle: parentHandle,
            newName: nil
        )
        
        XCTAssertTrue(isCopySuccess)
        XCTAssertEqual(mockSdk.copyNodeWithSameNameCallCount, 1)
    }
    
    func testCopyNodeIfExistsWithSameFingerprint_nodeIsAlreadyOnTheParentNodeDestination_shouldReturnTrue() {
        let fingerprint = "Fingerprint 0"
        let parentHandle: HandleEntity = 1
        let mockSdk = MockSdk(
            nodes: [
                MockNode(handle: parentHandle, name: "Folder node destination name"),
                MockNode(handle: 2, name: "File node to be copied name", parentHandle: parentHandle, fingerprint: fingerprint)
            ],
            nodeFingerprint: fingerprint
        )
        
        let sut = makeSUT(sdk: mockSdk)
        let isCopySuccess = sut.copyNodeIfExistsWithSameFingerprint(
            at: "fingerprintPath",
            parentHandle: parentHandle,
            newName: "File node 1"
        )
        
        XCTAssertTrue(isCopySuccess)
        XCTAssertEqual(mockSdk.copyNodeWithNewNameCallCount, 0)
        XCTAssertEqual(mockSdk.copyNodeWithSameNameCallCount, 0)
    }
    
    func testCopyNodeIfExistsWithSameFingerprint_parentNodeNotFound_shouldReturnFalse() {
        let fingerprint = "Fingerprint 0"
        let mockSdk = MockSdk(
            nodes: [
                MockNode(handle: 1, name: "File node to be copied name", fingerprint: fingerprint)
            ],
            nodeFingerprint: fingerprint
        )
        
        let sut = makeSUT(sdk: mockSdk)
        let isCopySuccess = sut.copyNodeIfExistsWithSameFingerprint(
            at: "fingerprintPath",
            parentHandle: 2,
            newName: "File node 1"
        )
        
        XCTAssertFalse(isCopySuccess)
        XCTAssertEqual(mockSdk.copyNodeWithNewNameCallCount, 0)
        XCTAssertEqual(mockSdk.copyNodeWithSameNameCallCount, 0)
    }
    
    func testCopyNodeIfExistsWithSameFingerprint_fingerprintAndNodeNotFound_shouldReturnFalse() {
        let mockSdk = mockSdk(nodeHandle: 1, toParentHandle: 2, nodeFingerprint: nil)
        
        let sut = makeSUT(sdk: mockSdk)
        let isCopySuccess = sut.copyNodeIfExistsWithSameFingerprint(
            at: "fingerprintPath",
            parentHandle: 2,
            newName: "File node 1"
        )
        
        XCTAssertFalse(isCopySuccess)
        XCTAssertEqual(mockSdk.copyNodeWithNewNameCallCount, 0)
        XCTAssertEqual(mockSdk.copyNodeWithSameNameCallCount, 0)
    }
    
    // MARK: - Copy node
    func testCopyNode_parentNodeNotFound_shouldThrowNodeNotFound() async {
        let sut = makeSUT(sdk: MockSdk(nodes: []))
        
        await XCTAsyncAssertThrowsError(
            try await sut.copyNode(handle: 1, in: 2, newName: nil, isFolderLink: false)
        ) { error in
            XCTAssertEqual(error as? CopyOrMoveErrorEntity, .nodeNotFound)
        }
    }
    
    func testCopyNode_failedWithApiEOverQuota_shouldThrowOverQuota() async {
        let sut = makeSUT(
            sdk: mockSdk(nodeHandle: 1, toParentHandle: 2, megaSetError: MockError(errorType: .apiEOverQuota))
        )
        
        await XCTAsyncAssertThrowsError(
            try await sut.copyNode(handle: 1, in: 2, newName: nil, isFolderLink: false)
        ) { error in
            XCTAssertEqual(error as? CopyOrMoveErrorEntity, .overQuota)
        }
    }
    
    func testCopyNode_failedWithErrorOtherThanApiEOverQuota_shouldThrowNodeCopyFailed() async {
        let sut = makeSUT(
            sdk: mockSdk(nodeHandle: 1, toParentHandle: 2, megaSetError: MockError(errorType: .anyFailingErrorType(excluding: [.apiEOverQuota])))
        )
        
        await XCTAsyncAssertThrowsError(
            try await sut.copyNode(handle: 1, in: 2, newName: nil, isFolderLink: false)
        ) { error in
            XCTAssertEqual(error as? CopyOrMoveErrorEntity, .nodeCopyFailed)
        }
    }
    
    func testCopyNode_isFolderLinkTrue_failedAuthorization_shouldThrowNodeAuthorizeFailed() async {
        let sut = makeSUT(
            sdk: MockSdk(
                nodes: [MockNode(handle: 2, name: "Folder node destination name")]
            ),
            sharedFolderSdk: MockFolderSdk(
                nodes: [MockNode(handle: 1, name: "File node to be copied name")]
            )
        )
        
        await XCTAsyncAssertThrowsError(
            try await sut.copyNode(handle: 1, in: 2, newName: nil, isFolderLink: true)
        ) { error in
            XCTAssertEqual(error as? CopyOrMoveErrorEntity, .nodeAuthorizeFailed)
        }
    }
    
    func testCopyNode_isFolderLinkTrue_copyNodeSuccessWithNewName_shouldReturnHandleEntity() async {
        let expectedHandle: HandleEntity = 1
        let parentHandle: HandleEntity = 2
        let mockSdk = mockSdk(
            nodeHandle: expectedHandle,
            toParentHandle: parentHandle,
            copiedNodeHandles: [expectedHandle: expectedHandle]
        )
        let authorizedSharedNode = MockNode(handle: expectedHandle, name: "Shared file node to be copied name")
        let mockSharedFolderSdk = MockFolderSdk(nodes: [authorizedSharedNode])
        
        let sut = makeSUT(sdk: mockSdk, sharedFolderSdk: mockSharedFolderSdk)
        mockSharedFolderSdk.mockAuthorizeNode(with: authorizedSharedNode)
        
        do {
            let nodeHandle = try await sut.copyNode(handle: expectedHandle, in: parentHandle, newName: "New name", isFolderLink: true)
            XCTAssertEqual(nodeHandle, expectedHandle)
            XCTAssertEqual(mockSdk.copyNodeWithNewNameCallCount, 1)
        } catch {
            XCTFail("Received unexpected error \(error)")
        }
    }
    
    func testCopyNode_isFolderLinkTrue_copyNodeSuccessWithSameName_shouldReturnHandleEntity() async {
        let expectedHandle: HandleEntity = 1
        let parentHandle: HandleEntity = 2
        let mockSdk = mockSdk(
            nodeHandle: expectedHandle,
            toParentHandle: parentHandle,
            copiedNodeHandles: [expectedHandle: expectedHandle]
        )
        let authorizedSharedNode = MockNode(handle: expectedHandle, name: "Shared file node to be copied name")
        let mockSharedFolderSdk = MockFolderSdk(nodes: [authorizedSharedNode])
        
        let sut = makeSUT(sdk: mockSdk, sharedFolderSdk: mockSharedFolderSdk)
        mockSharedFolderSdk.mockAuthorizeNode(with: authorizedSharedNode)
        
        do {
            let nodeHandle = try await sut.copyNode(handle: expectedHandle, in: parentHandle, newName: nil, isFolderLink: true)
            XCTAssertEqual(nodeHandle, expectedHandle)
            XCTAssertEqual(mockSdk.copyNodeWithSameNameCallCount, 1)
        } catch {
            XCTFail("Received unexpected error \(error)")
        }
    }
    
    func testCopyNode_isFolderLinkFalse_copyingNodeNotFound_shouldThrowNodeNotFound() async {
        let sut = makeSUT(
            sdk: MockSdk(
                nodes: [MockNode(handle: 2, name: "Folder node destination name")]
            ),
            sharedFolderSdk: MockFolderSdk(
                nodes: []
            )
        )
        
        await XCTAsyncAssertThrowsError(
            try await sut.copyNode(handle: 1, in: 2, newName: nil, isFolderLink: false)
        ) { error in
            XCTAssertEqual(error as? CopyOrMoveErrorEntity, .nodeNotFound)
        }
    }
    
    func testCopyNode_isFolderLinkFalse_copyNodeSuccessWithNewName_shouldReturnHandleEntity() async {
        let expectedHandle: HandleEntity = 1
        let parentHandle: HandleEntity = 2
        let mockSdk = mockSdk(
            nodeHandle: expectedHandle,
            toParentHandle: parentHandle,
            copiedNodeHandles: [expectedHandle: expectedHandle]
        )
        let sut = makeSUT(sdk: mockSdk)
        
        do {
            let nodeHandle = try await sut.copyNode(handle: expectedHandle, in: parentHandle, newName: "New name", isFolderLink: false)
            XCTAssertEqual(nodeHandle, expectedHandle)
            XCTAssertEqual(mockSdk.copyNodeWithNewNameCallCount, 1)
        } catch {
            XCTFail("Received unexpected error \(error)")
        }
    }
    
    func testCopyNode_isFolderLinkFalse_copyNodeSuccessWithSameName_shouldReturnHandleEntity() async {
        let expectedHandle: HandleEntity = 1
        let parentHandle: HandleEntity = 2
        let mockSdk = mockSdk(
            nodeHandle: expectedHandle,
            toParentHandle: parentHandle,
            copiedNodeHandles: [expectedHandle: expectedHandle]
        )
        let sut = makeSUT(sdk: mockSdk)
        
        do {
            let nodeHandle = try await sut.copyNode(handle: expectedHandle, in: parentHandle, newName: nil, isFolderLink: false)
            XCTAssertEqual(nodeHandle, expectedHandle)
            XCTAssertEqual(mockSdk.copyNodeWithSameNameCallCount, 1)
        } catch {
            XCTFail("Received unexpected error \(error)")
        }
    }
    
    // MARK: - Move node
    func testMoveNode_parentNodeNotFound_shouldThrowNodeNotFound() async {
        let nodeHandle: HandleEntity = 1
        let sut = makeSUT(
            sdk: MockSdk(nodes: [MockNode(handle: nodeHandle, name: "File node to be moved name")])
        )
        
        await XCTAsyncAssertThrowsError(
            try await sut.moveNode(handle: nodeHandle, in: 2, newName: nil)
        ) { error in
            XCTAssertEqual(error as? CopyOrMoveErrorEntity, .nodeNotFound)
        }
    }
    
    func testMoveNode_nodeNotFound_shouldThrowNodeNotFound() async {
        let parentNodeHandle: HandleEntity = 2
        let sut = makeSUT(
            sdk: MockSdk(nodes: [MockNode(handle: parentNodeHandle, name: "Folder node destination name")])
        )
        
        await XCTAsyncAssertThrowsError(
            try await sut.moveNode(handle: 1, in: parentNodeHandle, newName: nil)
        ) { error in
            XCTAssertEqual(error as? CopyOrMoveErrorEntity, .nodeNotFound)
        }
    }
    
    func testMoveNode_failedWithCircularError_shouldThrowNodeMoveFailedCircularLinkage() async {
        let nodeHandle: HandleEntity = 1
        let parentHandle: HandleEntity = 2
        let sut = makeSUT(
            sdk: mockSdk(
                nodeHandle: nodeHandle,
                toParentHandle: parentHandle,
                requestResult: .failure(MockError(errorType: .apiECircular))
            )
        )
        
        await XCTAsyncAssertThrowsError(
            try await sut.moveNode(handle: nodeHandle, in: parentHandle, newName: nil)
        ) { error in
            XCTAssertEqual(error as? CopyOrMoveErrorEntity, .nodeMoveFailedCircularLinkage)
        }
    }
    
    func testMoveNode_failedWithOtherErrorsThanCircularError_shouldThrowNodeCopyFailed() async {
        let nodeHandle: HandleEntity = 1
        let parentHandle: HandleEntity = 2
        let sut = makeSUT(
            sdk: mockSdk(
                nodeHandle: nodeHandle,
                toParentHandle: parentHandle,
                requestResult: .failure(MockError(errorType: .anyFailingErrorType(excluding: [.apiECircular])))
            )
        )
        
        await XCTAsyncAssertThrowsError(
            try await sut.moveNode(handle: nodeHandle, in: parentHandle, newName: nil)
        ) { error in
            XCTAssertEqual(error as? CopyOrMoveErrorEntity, .nodeCopyFailed)
        }
    }
    
    func testMoveNode_successRequestWithSameName_shouldReturnHandleEntity() async {
        let nodeHandle: HandleEntity = 1
        let parentHandle: HandleEntity = 2
        let mockSdk = mockSdk(
            nodeHandle: nodeHandle,
            toParentHandle: parentHandle,
            requestResult: .success(MockRequest(handle: nodeHandle))
        )
        let sut = makeSUT(sdk: mockSdk)
        
        do {
            let movedNodeHandle = try await sut.moveNode(handle: nodeHandle, in: parentHandle, newName: nil)
            XCTAssertEqual(movedNodeHandle, nodeHandle)
            XCTAssertEqual(mockSdk.moveNodeWithSameNameCallCount, 1)
        } catch {
            XCTFail("Received unexpected error \(error)")
        }
    }
    
    func testMoveNode_successRequestWithNewName_shouldReturnHandleEntity() async {
        let nodeHandle: HandleEntity = 1
        let parentHandle: HandleEntity = 2
        let mockSdk = mockSdk(
            nodeHandle: nodeHandle,
            toParentHandle: parentHandle,
            requestResult: .success(MockRequest(handle: nodeHandle))
        )
        let sut = makeSUT(sdk: mockSdk)
        
        do {
            let movedNodeHandle = try await sut.moveNode(handle: nodeHandle, in: parentHandle, newName: "New name")
            XCTAssertEqual(movedNodeHandle, nodeHandle)
            XCTAssertEqual(mockSdk.moveNodeWithNewNameCallCount, 1)
        } catch {
            XCTFail("Received unexpected error \(error)")
        }
    }
    
    // MARK: - Helper
    private func makeSUT(sdk: MockSdk = MockSdk(), sharedFolderSdk: MockFolderSdk = MockFolderSdk()) -> NodeActionsRepository {
        NodeActionsRepository(sdk: sdk, sharedFolderSdk: sharedFolderSdk)
    }
    
    private func mockSdk(
        nodeHandle: HandleEntity,
        toParentHandle parentHandle: HandleEntity,
        megaSetError: MockError = MockError(errorType: .apiOk),
        copiedNodeHandles: [HandleEntity: HandleEntity] = [:],
        requestResult: MockSdkRequestResult = .failure(MockError.failingError),
        nodeFingerprint: String? = nil
    ) -> MockSdk {
        MockSdk(
            nodes: [
                MockNode(handle: parentHandle, name: "Folder node destination name"),
                MockNode(handle: nodeHandle, name: "File node to be copied or moved name", fingerprint: nodeFingerprint)
            ],
            megaSetError: megaSetError.type,
            copiedNodeHandles: copiedNodeHandles,
            requestResult: requestResult,
            nodeFingerprint: nodeFingerprint
        )
    }
}
