@testable import MEGA
import MEGAAppSDKRepoMock
import MEGATest
import XCTest

final class NodeInfoRepositoryTests: XCTestCase {
    
    // MARK: - folderLinkLogout
    func testFolderLinkLogout_whenCalled_logoutSDK() {
        let (sut, _, mockFolderSdk, _, _) = makeSUT()
        
        sut.folderLinkLogout()
        
        XCTAssertEqual(mockFolderSdk.folderLinkLogoutCallCount, 1)
    }
    
    // MARK: - nodeFromHandle
    func testNodeFromHandle_whenCalled_callNode() {
        let (sut, mockSdk, _, _, _) = makeSUT(sdk: MockSdk(), folderSdk: MockFolderSdk(isLoggedIn: true))
        
        _ = sut.node(fromHandle: .invalid)
        
        XCTAssertEqual(mockSdk.nodeForHandleCallCount, 1)
    }
    
    // MARK: - pathFromHandle
    func testPathFromHandle_whenCalled_searchNode() {
        let (sut, mockSdk, _, _, _) = makeSUT(sdk: MockSdk(nodes: []), folderSdk: MockFolderSdk(isLoggedIn: true))
        
        _ = sut.path(fromHandle: .invalid)
        
        XCTAssertEqual(mockSdk.nodeForHandleCallCount, 1)
    }
    
    func testPathFromHandle_whenNotFoundHandle_returnsNilPath() {
        let (sut, _, _, _, _) = makeSUT(sdk: MockSdk(nodes: []), folderSdk: MockFolderSdk(isLoggedIn: true))
        
        let node = sut.path(fromHandle: .invalid)
        
        XCTAssertNil(node)
    }
    
    func testPathFromHandle_whenHasValidNode_searchPathFromOfflineFileInfo() {
        let node = anyNode(handle: 1)
        let (sut, _, _, offlineFileInfoRepository, _) = makeSUT(
            sdk: MockSdk(nodes: [node]),
            folderSdk: MockFolderSdk(isLoggedIn: true),
            offlineInfoRepository: MockOfflineInfoRepository(
                result: .success,
                isOffline: true
            )
        )
        
        _ = sut.path(fromHandle: node.handle)
        
        XCTAssertEqual(offlineFileInfoRepository.localPathfromNodeCallCount, 1)
    }
    
    func testPathFromHandle_whenHasValidNodeAndNilOfflinePath_searchPathFromStreamingInfo() {
        let node = anyNode(handle: 1)
        let (sut, _, _, _, streamingInfoRepository) = makeSUT(
            sdk: MockSdk(nodes: [node]),
            folderSdk: MockFolderSdk(isLoggedIn: true),
            offlineInfoRepository: MockOfflineInfoRepository(result: .failure(.generic)),
            streamingInfoRepository: MockStreamingInfoRepository(result: .success)
        )
        
        _ = sut.path(fromHandle: node.handle)
        
        XCTAssertEqual(streamingInfoRepository.pathFromNodeCallCount, 1)
    }
    
    // MARK: - infoFromNodes
    func testInfoFromNodes_whenNilNodes_returnsNilPlayerItems() {
        let (sut, _, _, _, _) = makeSUT(sdk: MockSdk(), folderSdk: MockFolderSdk(isLoggedIn: true))
        
        let playerItems = sut.info(fromNodes: nil)
        
        XCTAssertNil(playerItems)
    }
    
    func testInfoFromNodes_whenSingleNode_returnsNilPlayerItemOnNotFoundItem() {
        let (sut, _, _, _, _) = makeSUT(sdk: MockSdk(nodes: []), folderSdk: MockFolderSdk(isLoggedIn: true))
        
        let playerItems = sut.info(fromNodes: nil)
        
        XCTAssertNil(playerItems)
    }
    
    func testInfoFromNodes_whenSingleNode_returnsSinglePlayerItem() {
        let node = anyNode(handle: 1, name: "any-name")
        let nodes = [node]
        let (sut, _, _, _, _) = makeSUT(
            sdk: MockSdk(nodes: nodes),
            folderSdk: MockFolderSdk(isLoggedIn: true),
            offlineInfoRepository: MockOfflineInfoRepository(result: .failure(.generic)),
            streamingInfoRepository: MockStreamingInfoRepository(result: .success)
        )
        
        let playerItems = sut.info(fromNodes: nodes)
        
        XCTAssertEqual(nodes.count, playerItems?.count)
        XCTAssertEqual(nodes.first?.name, playerItems?.first?.name)
        XCTAssertEqual(nodes.first, playerItems?.first?.node)
    }
    
    func testInfoFromNodes_whenMoreThanOneItems_returnsMoreThanOneItems() {
        let node1 = anyNode(handle: 1, name: "any-name-1")
        let node2 = anyNode(handle: 2, name: "any-name-2")
        let nodes = [node1, node2]
        let (sut, _, _, _, _) = makeSUT(
            sdk: MockSdk(nodes: nodes),
            folderSdk: MockFolderSdk(isLoggedIn: true),
            offlineInfoRepository: MockOfflineInfoRepository(result: .failure(.generic)),
            streamingInfoRepository: MockStreamingInfoRepository(result: .success)
        )
        
        let playerItems = sut.info(fromNodes: nodes)
        
        XCTAssertEqual(nodes.count, playerItems?.count)
        playerItems?.enumerated().forEach { (index, playerItem) in
            XCTAssertEqual(nodes[index].name, playerItem.name)
            XCTAssertEqual(nodes[index], playerItem.node)
        }
    }
    
    // MARK: - childrenInfoFromParentHandle
    func testChildrenInfoFromParentHandle_whenInvalidNode_returnsNil() {
        let node1 = anyNode(handle: 1, name: "any-invalid-node-1")
        let (sut, _, _, _, _) = makeSUT(sdk: MockSdk(nodes: [node1]), folderSdk: MockFolderSdk(isLoggedIn: true))
        
        let playerItems = sut.childrenInfo(fromParentHandle: .invalid)
        
        XCTAssertNil(playerItems)
    }
    
    func testChildrenInfoFromParentHandle_withValidAudioNodes_returnsSingleItem() {
        let parentNode = anyNode(handle: 1, name: "any-valid-node-1.mp3", parentHandle: 100)
        let childNode = anyNode(handle: 2, name: "any-valid-node-2.mp3", parentHandle: 1)
        let (sut, _, _, _, _) = makeSUT(
            sdk: MockSdk(nodes: [parentNode, childNode]),
            folderSdk: MockFolderSdk(isLoggedIn: true),
            offlineInfoRepository: MockOfflineInfoRepository(result: .success)
        )
        
        guard let playerItems = sut.childrenInfo(fromParentHandle: parentNode.handle) else {
            XCTFail("Expect to have empty items, got nil instead.")
            return
        }
        
        XCTAssertEqual(playerItems.count, 1)
        playerItems.enumerated().forEach { (index, playerItem) in
            XCTAssertEqual(playerItem.node?.parentHandle, 1, "Expect to have correct parent handle 1, got wrong instead at index: \(index)")
        }
    }
    
    func testChildrenInfoFromParentHandle_withValidAudioNodes_returnsMoreThanOneItems() {
        let parentNode = anyNode(handle: 1, name: "any-valid-node-1.mp3", parentHandle: 100)
        let childNode1 = anyNode(handle: 2, name: "any-valid-node-2.mp3", parentHandle: 1)
        let childNode2 = anyNode(handle: 3, name: "any-valid-node-3.mp3", parentHandle: 1)
        let (sut, _, _, _, _) = makeSUT(
            sdk: MockSdk(nodes: [parentNode, childNode1, childNode2]),
            folderSdk: MockFolderSdk(isLoggedIn: true),
            offlineInfoRepository: MockOfflineInfoRepository(result: .success)
        )
        
        guard let playerItems = sut.childrenInfo(fromParentHandle: parentNode.handle) else {
            XCTFail("Expect to have empty items, got nil instead.")
            return
        }
        
        XCTAssertEqual(playerItems.count, 2)
        playerItems.enumerated().forEach { (index, playerItem) in
            XCTAssertEqual(playerItem.node?.parentHandle, 1, "Expect to have correct parent handle 1, got wrong instead at index: \(index)")
        }
    }
    
    // MARK: - folderInfoFromParentHandle
    func testFolderChildrenInfoFromParentHandle_whenInvalidNode_returnsNil() {
        let node1 = anyNode(handle: 1, name: "any-invalid-node-1")
        let (sut, _, _, _, _) = makeSUT(sdk: MockSdk(nodes: [node1]), folderSdk: MockFolderSdk(isLoggedIn: true, nodes: [node1]))
        
        let playerItems = sut.folderChildrenInfo(fromParentHandle: .invalid)
        
        XCTAssertNil(playerItems)
    }
    
    func testFolderChildrenInfoFromParentHandle_withValidAudioNodes_returnsSingleItem() {
        let parentNode = anyNode(handle: 1, name: "any-valid-node-1.mp3", parentHandle: 100)
        let childNode = anyNode(handle: 2, name: "any-valid-node-2.mp3", parentHandle: 1)
        let nodes = [parentNode, childNode]
        let (sut, _, mockFolderSdk, _, _) = makeSUT(
            sdk: MockSdk(nodes: nodes),
            folderSdk: MockFolderSdk(isLoggedIn: true, nodes: nodes),
            offlineInfoRepository: MockOfflineInfoRepository(result: .success),
            streamingInfoRepository: MockStreamingInfoRepository(result: .success)
        )
        nodes.forEach(mockFolderSdk.mockAuthorizeNode(with:))
        
        guard let playerItems = sut.folderChildrenInfo(fromParentHandle: parentNode.handle) else {
            XCTFail("Expect to have empty items, got nil instead.")
            return
        }
        
        XCTAssertEqual(playerItems.count, 1)
        playerItems.enumerated().forEach { (index, playerItem) in
            XCTAssertEqual(playerItem.node?.parentHandle, 1, "Expect to have correct parent handle 1, got wrong instead at index: \(index)")
        }
    }
    
    func testFolderChildrenInfoFromParentHandle_withValidAudioNodes_returnsMoreThanOneItems() {
        let parentNode = anyNode(handle: 1, name: "any-valid-node-1.mp3", parentHandle: 100)
        let childNode1 = anyNode(handle: 2, name: "any-valid-node-2.mp3", parentHandle: 1)
        let childNode2 = anyNode(handle: 3, name: "any-valid-node-2.mp3", parentHandle: 1)
        let nodes = [parentNode, childNode1, childNode2]
        let (sut, _, mockFolderSdk, _, _) = makeSUT(
            sdk: MockSdk(nodes: nodes),
            folderSdk: MockFolderSdk(isLoggedIn: true, nodes: nodes),
            offlineInfoRepository: MockOfflineInfoRepository(result: .success),
            streamingInfoRepository: MockStreamingInfoRepository(result: .success)
        )
        nodes.forEach(mockFolderSdk.mockAuthorizeNode(with:))
        
        guard let playerItems = sut.folderChildrenInfo(fromParentHandle: parentNode.handle) else {
            XCTFail("Expect to have empty items, got nil instead.")
            return
        }
        
        XCTAssertEqual(playerItems.count, 2)
        playerItems.enumerated().forEach { (index, playerItem) in
            XCTAssertEqual(playerItem.node?.parentHandle, 1, "Expect to have correct parent handle 1, got wrong instead at index: \(index)")
        }
    }
    
    // MARK: - Helpers
    private func makeSUT(
        sdk: MockSdk = MockSdk(),
        folderSdk: MockFolderSdk = MockFolderSdk(),
        megaStore: MEGAStore = MEGAStore(),
        offlineInfoRepository: MockOfflineInfoRepository = MockOfflineInfoRepository(result: .success),
        streamingInfoRepository: MockStreamingInfoRepository = MockStreamingInfoRepository(result: .success),
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (
        sut: NodeInfoRepository,
        mockSdk: MockSdk,
        mockFolderSdk: MockFolderSdk,
        offlineFileInfoRepository: MockOfflineInfoRepository,
        streamingInfoRepository: MockStreamingInfoRepository
    ) {
        let sut = NodeInfoRepository(
            sdk: sdk,
            folderSDK: folderSdk,
            megaStore: megaStore,
            offlineFileInfoRepository: offlineInfoRepository,
            streamingInfoRepository: streamingInfoRepository
        )
        trackForMemoryLeaks(on: sut, file: file, line: line)
        trackForMemoryLeaks(on: sdk, file: file, line: line)
        trackForMemoryLeaks(on: folderSdk, file: file, line: line)
        trackForMemoryLeaks(on: megaStore, file: file, line: line)
        trackForMemoryLeaks(on: offlineInfoRepository, file: file, line: line)
        trackForMemoryLeaks(on: offlineInfoRepository, file: file, line: line)
        return (sut, sdk, folderSdk, offlineInfoRepository, streamingInfoRepository)
    }
    
    private func anyNode(handle: MEGAHandle = 1, name: String = "", parentHandle: MEGAHandle = 100) -> MockNode {
        MockNode(handle: handle, name: name, parentHandle: parentHandle)
    }

}
