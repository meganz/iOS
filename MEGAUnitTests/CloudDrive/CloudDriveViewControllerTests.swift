import Combine
@testable import MEGA
import MEGADomain
import MEGADomainMock
@testable import MEGASDKRepoMock
import XCTest

final class CloudDriveViewControllerTests: XCTestCase {
    
    class MockViewModeStoreObjC: ViewModeStoringObjC {
        func save(viewMode: ViewModePreferenceEntity, forObjC location: MEGA.ViewModeLocation_ObjWrapper) {
            viewModesPassedIn.append(viewMode)
        }
        
        func viewMode(for location: MEGA.ViewModeLocation_ObjWrapper) -> ViewModePreferenceEntity {
            viewModeToReturn
        }
        
        var viewModeToReturn: ViewModePreferenceEntity = .list
        var viewModesPassedIn = [ViewModePreferenceEntity]()
        
        init() {}
    }
    
    // MARK: - NodeAction favorite
    
    func testNodeAction_whenSelectFavoriteOnViewModePreferenceEntityThumbnailAndHasFolderTypeOnly_reloadCollectionAtIndexPath() {
        let viewModeStore = MockViewModeStoreObjC()
        viewModeStore.viewModeToReturn = .thumbnail
        let displayMode = cloudDriveDisplayMode()
        let selectedNode = anyNode(handle: .min, nodeType: .folder)
        let mockNodeActionViewController = makeNodeActionViewController(nodes: [selectedNode], displayMode: displayMode)
        let sut = makeSUT(nodes: [selectedNode], displayMode: displayMode)
        sut.viewModePreference_ObjC = ViewModePreferenceEntity.thumbnail.rawValue
        setNoEditingState(on: sut)
        sut.viewModeStore = viewModeStore
        sut.simulateUserSelectFavorite(mockNodeActionViewController, selectedNode)
        
        let exp = expectation(description: "reload data at called")
        let subscription = sut.collectionView().$messages
            .dropFirst()
            .sink { messages in
                XCTAssertEqual(messages, [.reloadDataAt([IndexPath(item: 0, section: 0)])])
                exp.fulfill()
            }
        
        sut.simulateOnNodesUpdateReloadUI(nodeList: sut.nodes)
        
        wait(for: [exp], timeout: 1.0)
        subscription.cancel()
    }
    
    func testNodeAction_whenSelectFavoriteOnViewModePreferenceEntityThumbnailAndHasFileTypeOnly_reloadCollectionAtIndexPath() {
        let viewModeStore = MockViewModeStoreObjC()
        viewModeStore.viewModeToReturn = .thumbnail
        let displayMode = cloudDriveDisplayMode()
        let selectedNode = anyNode(handle: .min, nodeType: .file)
        let mockNodeActionViewController = makeNodeActionViewController(nodes: [selectedNode], displayMode: displayMode)
        let sut = makeSUT(nodes: [selectedNode], displayMode: displayMode, viewModeStore: viewModeStore)
        sut.viewModePreference_ObjC = ViewModePreferenceEntity.thumbnail.rawValue
        setNoEditingState(on: sut)
        sut.simulateUserSelectFavorite(mockNodeActionViewController, selectedNode)
        
        let exp = expectation(description: "reload data at called")
        let subscription = sut.collectionView().$messages
            .dropFirst()
            .sink { messages in
                XCTAssertEqual(messages, [.reloadDataAt([IndexPath(item: 0, section: 1)])])
                exp.fulfill()
            }
        
        sut.simulateOnNodesUpdateReloadUI(nodeList: sut.nodes)
        
        wait(for: [exp], timeout: 1.0)
        subscription.cancel()
    }
    
    // MARK: - NodeAction Remove
    
    func testNodeAction_whenSelectRubbishBinOnRubbishBinPage_reloadCollection() {
        let viewModeStore = MockViewModeStoreObjC()
        viewModeStore.viewModeToReturn = .thumbnail
        let displayMode = rubbishBinDisplayMode()
        let selectedNode = anyNode(handle: .min, nodeType: .file)
        let mockNodeActionViewController = makeNodeActionViewController(nodes: [selectedNode], displayMode: displayMode)
        let sut = makeSUT(nodes: [selectedNode], displayMode: displayMode, viewModeStore: viewModeStore)
        setNoEditingState(on: sut)
        sut.simulateUserSelectDelete(mockNodeActionViewController, selectedNode)
        let exp = expectation(description: "reload data called")
        let subscription = sut.collectionView().$messages
            .dropFirst()
            .sink { messages in
                XCTAssertEqual(messages, [.reloadData])
                exp.fulfill()
            }
        
        sut.simulateOnNodesUpdateReloadUI(nodeList: sut.nodes)
        
        wait(for: [exp], timeout: 1.0)
        subscription.cancel()
    }
    
    // MARK: - ReloadUI
    
    func testReloadUI_whenUpdatesOnOneNodeOnViewModePreferenceEntityThumbnailHasFileTypeOnlyAndSelectFavoriteAction_reloadCollectionAtIndexPath() {
        let viewModeStore = MockViewModeStoreObjC()
        viewModeStore.viewModeToReturn = .thumbnail
        let displayMode = cloudDriveDisplayMode()
        let sampleNode = anyNode(handle: anyHandle(), nodeType: .file)
        let sut = makeSUT(nodes: [sampleNode], displayMode: displayMode, viewModeStore: viewModeStore)
        setNoEditingState(on: sut)
        sut.viewModePreference_ObjC = ViewModePreferenceEntity.thumbnail.rawValue
        sut.wasSelectingFavoriteUnfavoriteNodeActionOption = true
        
        let exp = expectation(description: "reload data at called")
        let subscription = sut.collectionView().$messages
            .dropFirst()
            .sink { messages in
                XCTAssertEqual(messages, [.reloadDataAt([IndexPath(item: 0, section: 1) ])])
                exp.fulfill()
            }
        
        sut.simulateOnNodesUpdateReloadUI(nodeList: sut.nodes)
        
        wait(for: [exp], timeout: 1.0)
        subscription.cancel()
    }
    
    func testReloadUI_whenUpdatesMoreThanOneNodeOnViewModePreferenceEntityThumbnail_reloadCollection() {
        let viewModeStore = MockViewModeStoreObjC()
        viewModeStore.viewModeToReturn = .thumbnail
        let displayMode = cloudDriveDisplayMode()
        let firstNode = anyNode(handle: anyHandle(), nodeType: .file)
        let secondNode = anyNode(handle: anyHandle() + 1, nodeType: .file)
        let thirdNode = anyNode(handle: anyHandle() + 2, nodeType: .file)
        let sut = makeSUT(nodes: [firstNode, secondNode, thirdNode], displayMode: displayMode, viewModeStore: viewModeStore)
        setNoEditingState(on: sut)
        let exp = expectation(description: "reload data called")
        let subscription = sut.collectionView().$messages
            .dropFirst()
            .sink { messages in
                XCTAssertEqual(messages, [.reloadData])
                exp.fulfill()
            }
        
        sut.simulateOnNodesUpdateReloadUI(nodeList: sut.nodes)
        
        wait(for: [exp], timeout: 1.0)
        subscription.cancel()
    }
    
    // MARK: - findIndexPathForNode
    
    func testfindIndexPathForNode_whenHasFolderOnly_deliversCorrrectIndexPathForFolderNode() {
        let folderNode = anyNode(handle: anyHandle(), nodeType: .folder)
        let nodes = [folderNode]
        let sut = makeSUT(nodes: nodes)
        
        let indexPath = sut.findIndexPath(for: folderNode, source: nodes)
        
        XCTAssertEqual(indexPath.section, 0)
        XCTAssertEqual(indexPath.item, 0)
    }
    
    func testfindIndexPathForNode_whenHasMoreThanOneFolders_deliversCorrrectIndexPathForFirstFolderNode() {
        let firstFolderNode = anyNode(handle: anyHandle(), nodeType: .folder)
        let secondFolderNode = anyNode(handle: anyHandle() + 1, nodeType: .folder)
        let nodes = [firstFolderNode, secondFolderNode]
        let sut = makeSUT(nodes: nodes)
        
        let indexPath = sut.findIndexPath(for: firstFolderNode, source: nodes)
        
        XCTAssertEqual(indexPath.section, 0)
        XCTAssertEqual(indexPath.item, 0)
    }
    
    func testfindIndexPathForNode_whenHasTwoFolders_deliversCorrrectIndexPathForLastFolderNode() {
        let firstFolderNode = anyNode(handle: anyHandle(), nodeType: .folder)
        let secondFolderNode = anyNode(handle: anyHandle() + 1, nodeType: .folder)
        let nodes = [firstFolderNode, secondFolderNode]
        let sut = makeSUT(nodes: nodes)
        
        let indexPath = sut.findIndexPath(for: secondFolderNode, source: nodes)
        
        XCTAssertEqual(indexPath.section, 0)
        XCTAssertEqual(indexPath.item, 1)
    }
    
    func testfindIndexPathForNode_whenHasMoreThanTwoFolders_deliversCorrrectIndexPathForNonFirstAndLastFolderNode() {
        let firstFolderNode = anyNode(handle: anyHandle(), nodeType: .folder)
        let secondFolderNode = anyNode(handle: anyHandle() + 1, nodeType: .folder)
        let thirdFolderNode = anyNode(handle: anyHandle() + 2, nodeType: .folder)
        let nodes = [firstFolderNode, secondFolderNode, thirdFolderNode]
        let sut = makeSUT(nodes: nodes)
        
        let indexPath = sut.findIndexPath(for: secondFolderNode, source: nodes)
        
        XCTAssertEqual(indexPath.section, 0)
        XCTAssertEqual(indexPath.item, 1)
    }
    
    func testfindIndexPathForNode_whenHasFolderAndFile_deliversCorrrectIndexPathForFolderNode() {
        let folderNode = anyNode(handle: anyHandle(), nodeType: .folder)
        let fileNode = anyNode(handle: anyHandle() + 1, nodeType: .file)
        let nodes = [folderNode, fileNode]
        let sut = makeSUT(nodes: nodes)
        
        let indexPath = sut.findIndexPath(for: folderNode, source: nodes)
        
        XCTAssertEqual(indexPath.section, 0)
        XCTAssertEqual(indexPath.item, 0)
    }
    
    func testfindIndexPathForNode_whenHasFolderAndFile_deliversCorrrectIndexPathForFileNode() {
        let folderNode = anyNode(handle: anyHandle(), nodeType: .folder)
        let fileNode = anyNode(handle: anyHandle() + 1, nodeType: .file)
        let nodes = [folderNode, fileNode]
        let sut = makeSUT(nodes: nodes)
        
        let indexPath = sut.findIndexPath(for: fileNode, source: nodes)
        
        XCTAssertEqual(indexPath.section, 1)
        XCTAssertEqual(indexPath.item, 0)
    }
    
    func testfindIndexPathForNode_whenHasFolderAndMoreThanOneFiles_deliversCorrrectIndexPathForFolderNode() {
        let folderNode = anyNode(handle: anyHandle(), nodeType: .folder)
        let fileNode1 = anyNode(handle: anyHandle() + 1, nodeType: .file)
        let fileNode2 = anyNode(handle: anyHandle() + 2, nodeType: .file)
        let nodes = [folderNode, fileNode1, fileNode2]
        let sut = makeSUT(nodes: nodes)
        
        let indexPath = sut.findIndexPath(for: folderNode, source: nodes)
        
        XCTAssertEqual(indexPath.section, 0)
        XCTAssertEqual(indexPath.item, 0)
    }
    
    func testfindIndexPathForNode_whenHasFolderAndMoreThanOneFiles_deliversCorrrectIndexPathForLastFileNode() {
        let folderNode = anyNode(handle: anyHandle(), nodeType: .folder)
        let fileNode1 = anyNode(handle: anyHandle() + 1, nodeType: .file)
        let fileNode2 = anyNode(handle: anyHandle() + 2, nodeType: .file)
        let nodes = [folderNode, fileNode1, fileNode2]
        let sut = makeSUT(nodes: nodes)
        
        let indexPath = sut.findIndexPath(for: fileNode2, source: nodes)
        
        XCTAssertEqual(indexPath.section, 1)
        XCTAssertEqual(indexPath.item, 1)
    }
    
    func testfindIndexPathForNode_whenHasMoreThanOneFoldersAndOneFile_deliversCorrrectIndexPathForFirstFolderNode() {
        let folderNode1 = anyNode(handle: anyHandle(), nodeType: .folder)
        let folderNode2 = anyNode(handle: anyHandle() + 1, nodeType: .folder)
        let fileNode1 = anyNode(handle: anyHandle() + 2, nodeType: .file)
        let nodes = [folderNode1, folderNode2, fileNode1]
        let sut = makeSUT(nodes: nodes)
        
        let indexPath = sut .findIndexPath(for: folderNode1, source: nodes)
        
        XCTAssertEqual(indexPath.section, 0)
        XCTAssertEqual(indexPath.item, 0)
    }
    
    func testfindIndexPathForNode_whenHasMoreThanOneFoldersAndOneFile_deliversCorrrectIndexPathForFirstFileNode() {
        let folderNode1 = anyNode(handle: anyHandle(), nodeType: .folder)
        let folderNode2 = anyNode(handle: anyHandle() + 1, nodeType: .folder)
        let fileNode1 = anyNode(handle: anyHandle() + 2, nodeType: .file)
        let fileNode2 = anyNode(handle: anyHandle() + 3, nodeType: .file)
        let nodes = [folderNode1, folderNode2, fileNode1, fileNode2]
        let sut = makeSUT(nodes: nodes)
        
        let indexPath = sut.findIndexPath(for: fileNode2, source: nodes)
        
        XCTAssertEqual(indexPath.section, 1)
        XCTAssertEqual(indexPath.item, 1)
    }
    
    func testfindIndexPathForNode_whenHasMoreThanOneFoldersAndMoreThanOneFiles_deliversCorrrectIndexPathForLastFileNode() {
        let folderNode1 = anyNode(handle: anyHandle(), nodeType: .folder)
        let folderNode2 = anyNode(handle: anyHandle() + 1, nodeType: .folder)
        let fileNode1 = anyNode(handle: anyHandle() + 2, nodeType: .file)
        let nodes = [folderNode1, folderNode2, fileNode1]
        let sut = makeSUT(nodes: nodes)
        
        let indexPath = sut.findIndexPath(for: fileNode1, source: nodes)
        
        XCTAssertEqual(indexPath.section, 1)
        XCTAssertEqual(indexPath.item, 0)
    }
    
    func testfindIndexPathForNode_whenHasFileOnly_deliversCorrrectIndexPathForFileNode() {
        let fileNode = anyNode(handle: anyHandle(), nodeType: .file)
        let nodes = [fileNode]
        let sut = makeSUT(nodes: nodes)
        
        let indexPath = sut.findIndexPath(for: fileNode, source: nodes)
        
        XCTAssertEqual(indexPath.section, 1)
        XCTAssertEqual(indexPath.item, 0)
    }
    
    func testfindIndexPathForNode_whenHasTwoFiles_deliversCorrrectIndexPathForLastFileNode() {
        let firstFileNode = anyNode(handle: anyHandle(), nodeType: .file)
        let secondFileNode = anyNode(handle: anyHandle() + 1, nodeType: .file)
        let nodes = [firstFileNode, secondFileNode]
        let sut = makeSUT(nodes: nodes)
        
        let indexPath = sut.findIndexPath(for: secondFileNode, source: nodes)
        
        XCTAssertEqual(indexPath.section, 1)
        XCTAssertEqual(indexPath.item, 1)
    }
    
    func testfindIndexPathForNode_whenHasMoreThanTwoFiles_deliversCorrrectIndexPathForNonFirstAndLastFileNode() {
        let firstFileNode = anyNode(handle: anyHandle(), nodeType: .file)
        let secondFileNode = anyNode(handle: anyHandle() + 1, nodeType: .file)
        let thirdFileNode = anyNode(handle: anyHandle() + 2, nodeType: .file)
        let nodes = [firstFileNode, secondFileNode, thirdFileNode]
        let sut = makeSUT(nodes: nodes)
        
        let indexPath = sut.findIndexPath(for: secondFileNode, source: nodes)
        
        XCTAssertEqual(indexPath.section, 1)
        XCTAssertEqual(indexPath.item, 1)
    }
    
    // MARK: - CloudDriveViewController+ContextMenu
    
    func testSortMenu_whenSortFromRubbishBinOnThumbnailView_reloadData() {
        let viewModeStore = MockViewModeStoreObjC()
        viewModeStore.viewModeToReturn = .thumbnail
        let displayMode = rubbishBinDisplayMode()
        let selectedNode = anyNode(handle: .min, nodeType: .file)
        let sut = makeSUT(nodes: [selectedNode], displayMode: displayMode, viewModeStore: viewModeStore)
        
        let exp = expectation(description: "reload data called")
        
        let subscription = sut.collectionView().$messages
            .dropFirst()
            .sink { messages in
                XCTAssertEqual(messages, [.reloadData])
                exp.fulfill()
            }
        
        sut.viewWillAppear(true)
        
        SortOrderType.allCases.forEach {
            sut.simulateUserOpenContextMenuThen(select: $0)
        }
        
        wait(for: [exp], timeout: 1.0)
        subscription.cancel()
    }
    
    func testMapNodeListToArray_whenHasNoItem_sucessfullyMapItems() {
        let sut = makeSUT(nodes: [], displayMode: .cloudDrive)
        let emptyItems = MockNodeList(nodes: [])
        
        let result = sut.mapNodeListToArray(emptyItems)
        
        XCTAssertEqual(result.count, emptyItems.size)
    }
    
    func testMapNodeListToArray_whenHasSingleItem_sucessfullyMapItems() {
        let anyNode = anyNode(handle: .min, nodeType: .file)
        let sut = makeSUT(nodes: [anyNode], displayMode: .cloudDrive)
        let emptyItems = MockNodeList(nodes: [anyNode])
        
        let result = sut.mapNodeListToArray(emptyItems)
        
        XCTAssertEqual(result.count, emptyItems.size)
    }
    
    func testMapNodeListToArray_whenHasMoreThanOneItem_sucessfullyMapItems() {
        let anyNode = anyNode(handle: .min, nodeType: .file)
        let sut = makeSUT(nodes: [anyNode, anyNode], displayMode: .cloudDrive)
        let emptyItems = MockNodeList(nodes: [anyNode, anyNode])
        
        let result = sut.mapNodeListToArray(emptyItems)
        
        XCTAssertEqual(result.count, emptyItems.size)
    }
    
    func testChangeViewModePreference_toMediaDiscovery_shouldSetViewModeMediaDiscovery() {
        let sut = makeSUT(nodes: [], displayMode: .cloudDrive, parentNode: MockNode(handle: 0))
        sut.change(.mediaDiscovery)
        
        XCTAssertEqual(sut.children.count, 1)
        XCTAssertTrue(sut.children.allSatisfy { $0 == sut.mdViewController })
        XCTAssertEqual(sut.viewModePreference, .mediaDiscovery)
        XCTAssertEqual(sut.viewModePreference_ObjC, 3)
    }
    
    func testShouldProcessOnNodesUpdate_withDisplayModeCloudDriveAndNilParentNode_shouldReturnFalse() {
        let sut = makeSUT(nodes: [], displayMode: .cloudDrive, parentNode: MockNode(handle: 0))
        let sdk = MockSdk()
        let result = sut.shouldProcessOnNodesUpdate(with: .init(), childNodes: [], parentNode: nil, sdk: sdk, nodeUpdateRepository: MockNodeUpdateRepository())
        
        XCTAssertFalse(result)
        XCTAssertEqual(sdk.nodeForHandleCallCount, 0)
    }
    
    func testShouldProcessOnNodesUpdate_withDisplayModeCloudDriveAndParentNodeAndNoNewUpdates_shouldReturnFalse() {
        let parentNode = MockNode(handle: 0)
        let sdk = MockSdk()
        let nodeUpdateRepository = MockNodeUpdateRepository(shouldProcessOnNodesUpdate: false)
        let sut = makeSUT(nodes: [anyNode(handle: .min, nodeType: .file)], displayMode: .cloudDrive, parentNode: parentNode)
        let result = sut.shouldProcessOnNodesUpdate(with: .init(), childNodes: [], parentNode: parentNode, sdk: sdk, nodeUpdateRepository: nodeUpdateRepository)
        XCTAssertFalse(result)
        XCTAssertEqual(sdk.nodeForHandleCallCount, 0)
    }
    
    func testShouldProcessOnNodesUpdate_withDisplayModeCloudDriveAndParentNodeAndNewUpdates_shouldReturnTrue() {
        let parentNode = MockNode(handle: 0)
        let sdk = MockSdk()
        let nodeUpdateRepository = MockNodeUpdateRepository(shouldProcessOnNodesUpdate: true)
        let sut = makeSUT(nodes: [anyNode(handle: .min, nodeType: .file)], displayMode: .cloudDrive, parentNode: parentNode)
        let result = sut.shouldProcessOnNodesUpdate(with: .init(), childNodes: [], parentNode: parentNode, sdk: sdk, nodeUpdateRepository: nodeUpdateRepository)
        XCTAssertTrue(result)
        XCTAssertEqual(sdk.nodeForHandleCallCount, 0)
    }
    
    func testShouldProcessOnNodesUpdate_withDisplayModeRecentsAndNilRecentActionBucket_shouldReturnTrue() {
        let sdk = MockSdk()
        let nodeUpdateRepository = MockNodeUpdateRepository(shouldProcessOnNodesUpdate: true)
        let sut = makeSUT(nodes: [anyNode(handle: .min, nodeType: .file)], displayMode: .recents, recentActionsBucket: nil)
        let result = sut.shouldProcessOnNodesUpdate(with: .init(), childNodes: [], parentNode: nil, sdk: sdk, nodeUpdateRepository: nodeUpdateRepository)
        XCTAssertFalse(result)
        XCTAssertEqual(sdk.nodeForHandleCallCount, 0)
    }
    
    func testShouldProcessOnNodesUpdate_withDisplayModeRecentsAndNilSdkNodeForHandle_shouldReturnTrue() {
        let recentActionsBucket = MockRecentActionBucket(parentHandle: 0)
        let sdk = MockSdk(nodes: [])
        let nodeUpdateRepository = MockNodeUpdateRepository(shouldProcessOnNodesUpdate: false)
        let sut = makeSUT(nodes: [anyNode(handle: .min, nodeType: .file)], displayMode: .recents, recentActionsBucket: recentActionsBucket)
        let result = sut.shouldProcessOnNodesUpdate(with: .init(), childNodes: [], parentNode: nil, sdk: sdk, nodeUpdateRepository: nodeUpdateRepository)
        XCTAssertFalse(result)
        XCTAssertEqual(sdk.nodeForHandleCallCount, 1)
        XCTAssertFalse(nodeUpdateRepository.shouldProcessOnNodesUpdateCalled)
    }
    
    func testShouldProcessOnNodesUpdate_withDisplayModeRecentsAndValidSdkNodeForHandleAndNoNewUpdate_shouldReturnFalse() {
        let recentActionsBucket = MockRecentActionBucket(parentHandle: 1)
        let sdk = MockSdk(nodes: [MockNode(handle: 1)])
        let nodeUpdateRepository = MockNodeUpdateRepository(shouldProcessOnNodesUpdate: false)
        let sut = makeSUT(nodes: [anyNode(handle: .min, nodeType: .file)], displayMode: .recents, recentActionsBucket: recentActionsBucket)
        let result = sut.shouldProcessOnNodesUpdate(with: .init(), childNodes: [], parentNode: nil, sdk: sdk, nodeUpdateRepository: nodeUpdateRepository)
        XCTAssertFalse(result)
        XCTAssertEqual(sdk.nodeForHandleCallCount, 1)
        XCTAssertTrue(nodeUpdateRepository.shouldProcessOnNodesUpdateCalled)
    }
    
    func testShouldProcessOnNodesUpdate_withDisplayModeRecentsAndValidSdkNodeForHandleAndNewUpdate_shouldReturnTrue() {
        let recentActionsBucket = MockRecentActionBucket(parentHandle: 1)
        let sdk = MockSdk(nodes: [MockNode(handle: 1)])
        let nodeUpdateRepository = MockNodeUpdateRepository(shouldProcessOnNodesUpdate: true)
        let sut = makeSUT(nodes: [anyNode(handle: .min, nodeType: .file)], displayMode: .recents, recentActionsBucket: recentActionsBucket)
        let result = sut.shouldProcessOnNodesUpdate(with: .init(), childNodes: [], parentNode: nil, sdk: sdk, nodeUpdateRepository: nodeUpdateRepository)
        XCTAssertTrue(result)
        XCTAssertEqual(sdk.nodeForHandleCallCount, 1)
        XCTAssertTrue(nodeUpdateRepository.shouldProcessOnNodesUpdateCalled)
    }
    
    @MainActor
    func testReloadRecentActionBucketAfterNodeUpdates_withDisplayModeCloudDrive_shouldNotCallSdk() async {
        let sut = makeSUT(nodes: [], displayMode: .cloudDrive)
        let sdk = MockSdk()
        await sut.reloadRecentActionBucketAfterNodeUpdates(using: sdk)
        
        XCTAssertFalse(sdk.getRecentActionsAsyncCalled)
    }
    
    @MainActor
    func testReloadRecentActionBucketAfterNodeUpdates_withDisplayModeRecentsAndNilRecentsActionBucketAndSdkCallFails_shouldNotUpdateUI() async {
        let sdk = MockSdk(requestResult: .failure(MockError()))
        let sut = makeSUT(nodes: [], displayMode: .recents, recentActionsBucket: MockRecentActionBucket())
        sut.viewModePreference_ObjC = ViewModePreferenceEntity.thumbnail.rawValue
        await sut.reloadRecentActionBucketAfterNodeUpdates(using: sdk)
        
        XCTAssertTrue(sdk.getRecentActionsAsyncCalled)
        XCTAssertEqual(sut.collectionView().messages, [])
    }
    
    @MainActor
    func testReloadRecentActionBucketAfterNodeUpdates_withDisplayModeRecentsAndNilRecentsActionBucketAndSdkCallSucceedsWithNoNewUpdates_shouldNotUpdateUI() async {
        let sdk = MockSdk(requestResult: .success(MockRequest(handle: 0, recentActionsBuckets: [])))
        
        let sut = makeSUT(nodes: [], displayMode: .recents, recentActionsBucket: MockRecentActionBucket())
        sut.viewModePreference_ObjC = ViewModePreferenceEntity.thumbnail.rawValue
        await sut.reloadRecentActionBucketAfterNodeUpdates(using: sdk)
        
        XCTAssertTrue(sdk.getRecentActionsAsyncCalled)
        XCTAssertEqual(sut.collectionView().messages, [])
    }
    
    @MainActor
    func testReloadRecentActionBucketAfterNodeUpdates_withDisplayModeRecentsAndNilRecentsActionBucketAndSdkCallSucceedsWithNoNewUpdates_shouldUpdateUI() async {
        
        let originalBucket = MockRecentActionBucket.init(parentHandle: 1, nodeList: MockNodeList(nodes: [MockNode(handle: 100), MockNode(handle: 200)]))
        let responseBucket = MockRecentActionBucket.init(parentHandle: 1, nodeList: MockNodeList(nodes: [MockNode(handle: 200)]))
                                                         
        let sdk = MockSdk(requestResult: .success(MockRequest(handle: 0, recentActionsBuckets: [responseBucket])))
        
        let sut = makeSUT(nodes: [], displayMode: .recents, recentActionsBucket: originalBucket)
        sut.viewModePreference_ObjC = ViewModePreferenceEntity.thumbnail.rawValue
        
        let exp = expectation(description: "reload data called")
        let subscription = sut.collectionView().$messages
            .dropFirst()
            .sink { messages in
                XCTAssertEqual(messages, [.reloadData])
                exp.fulfill()
            }
        
        await sut.reloadRecentActionBucketAfterNodeUpdates(using: sdk)
        
        XCTAssertTrue(sdk.getRecentActionsAsyncCalled)
        await fulfillment(of: [exp], timeout: 1)
        subscription.cancel()
    }
    
    func testShouldDisplayAdsSlot_withDisplayModeCloudDrive_shouldReturnTrue() {
        let sut = makeSUT(nodes: [], displayMode: .cloudDrive)
        XCTAssertTrue(sut.shouldDisplayAdsSlot)
    }
    
    func testShouldDisplayAdsSlot_withDisplayModesNonCloudDrive_shouldReturnFalse() {
        let nonCloudDriveDisplayModes = (-1...25).compactMap { DisplayMode(rawValue: $0) }.filter { $0 != .cloudDrive }
        
        let results = nonCloudDriveDisplayModes.map { makeSUT(nodes: [], displayMode: $0).shouldDisplayAdsSlot }
        let expectedResults = [Bool](repeating: false, count: nonCloudDriveDisplayModes.count)
        
        XCTAssertEqual(results, expectedResults)
    }

    // MARK: - Helpers
    
    private func setNoEditingState(on sut: CloudDriveViewController) {
        sut.cdTableView?.tableView?.isEditing = false
        sut.cdCollectionView?.collectionView?.allowsMultipleSelection = false
    }
    
    private func anyNode(handle: MEGAHandle, nodeType: MEGANodeType) -> MockNode {
        MockNode.init(handle: handle, nodeType: nodeType, isFavourite: false)
    }
    
    private func makeNodeActionViewController(nodes: [MockNode], displayMode: DisplayMode) -> NodeActionViewController {
        let mockNodeActionViewController = NodeActionViewController(
            nodes: nodes,
            delegate: MockNodeActionViewController(),
            displayMode: displayMode,
            sender: "any-sender"
        )
        return mockNodeActionViewController
    }
    
    private func makeSUT(
        nodes: [MEGANode],
        displayMode: DisplayMode = .cloudDrive,
        parentNode: MEGANode? = nil,
        recentActionsBucket: MEGARecentActionBucket? = nil,
        viewModeStore: some ViewModeStoringObjC = MockViewModeStoreObjC()
    ) -> CloudDriveViewController {
        let storyboard = UIStoryboard(name: "Cloud", bundle: .main)
        let sut = storyboard.instantiateViewController(withIdentifier: "CloudDriveID") as! CloudDriveViewController
        sut.cdTableView = storyboard.instantiateViewController(withIdentifier: "CloudDriveTableID") as? CloudDriveTableViewController

        sut.nodes = MockNodeList(nodes: nodes)
        sut.parentNode = parentNode
        sut.recentActionBucket = recentActionsBucket
        sut.displayMode = displayMode
        sut.viewModeStoreCreator = {
            sut.viewModeStore = viewModeStore
        }
        sut.loadView()
        sut.viewDidLoad()
        sut.cdCollectionView = MockCloudDriveCollectionViewController()
        sut.cdTableView?.loadView()
        sut.cdCollectionView?.loadView()
        return sut
    }
    
    private func anyHandle() -> MEGAHandle {
        .min
    }
    
    private func cloudDriveDisplayMode() -> DisplayMode {
        .cloudDrive
    }
    
    private func rubbishBinDisplayMode() -> DisplayMode {
        .rubbishBin
    }
}

private extension CloudDriveViewController {
    func simulateUserSelectFavorite(_ nodeActionViewController: NodeActionViewController, _ selectedNode: MockNode) {
        wasSelectingFavoriteUnfavoriteNodeActionOption = true
        nodeAction(nodeActionViewController, didSelect: .favourite, for: selectedNode, from: "any-sender")
    }
    
    func simulateOnNodesUpdateReloadUI(nodeList: MEGANodeList?) {
        reloadUI(nodeList)
    }
    
    func collectionView() -> MockCloudDriveCollectionViewController {
        cdCollectionView as! MockCloudDriveCollectionViewController
    }
    
    func simulateUserSelectDelete(_ nodeActionViewController: NodeActionViewController, _ selectedNode: MockNode) {
        nodeAction(nodeActionViewController, didSelect: .remove, for: selectedNode, from: "any-sender")
    }
    
    func simulateUserOpenContextMenuThen(select selection: SortOrderType) {
        sortMenu(didSelect: selection)
    }
}

private final class MockNodeActionViewController: NodeActionViewControllerDelegate {
    
    func nodeAction(_ nodeAction: NodeActionViewController, didSelect action: MegaNodeActionType, for node: MEGANode, from sender: Any) { }
    
    func nodeAction(_ nodeAction: NodeActionViewController, didSelect action: MegaNodeActionType, forNodes nodes: [MEGANode], from sender: Any) { }
}

private final class MockCloudDriveCollectionViewController: CloudDriveCollectionViewController {
    enum Message: Equatable, CustomStringConvertible {
        case setCollectionViewEditing
        case reloadData
        case reloadDataAt([IndexPath])
        
        var description: String {
            switch self {
            case .setCollectionViewEditing: return "setCollectionViewEditing"
            case .reloadData: return "reloadData"
            case let .reloadDataAt(indexPaths): return "reloadDataAtIndexPaths:\(indexPaths)"
            }
        }
    }
    
    @Published private(set) var messages = [Message]()
    
    override func setCollectionViewEditing(_ editing: Bool, animated: Bool) {
        messages.append(.setCollectionViewEditing)
    }
    
    override func reloadData() {
        messages.append(.reloadData)
    }
    
    override func reloadData(at indexPaths: [IndexPath]) {
        messages.append(.reloadDataAt(indexPaths))
    }
}
