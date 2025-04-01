@testable import MEGA
import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGAAppPresentationMock
import MEGADomain
import MEGADomainMock
import MEGAL10n
import MEGASwiftUI
import MEGASwiftUIMock
import Notifications
import XCTest

@MainActor
final class NotificationsViewModelTests: XCTestCase {
    let nodeHandle = HandleEntity(123)
    let parentHandle = HandleEntity(456)
    
    func testNumberOfSections_shouldBeTwoSections() {
        let (sut, _, _) = makeSUT()
        XCTAssertEqual(sut.numberOfSections, 2)
    }
    
    func testNotificationsSectionNumberOfRows_shouldMatchNotificationsCount() async {
        let (sut, _, _) = makeSUT(
            notifications: [
                NotificationEntity(id: NotificationIDEntity(1)),
                NotificationEntity(id: NotificationIDEntity(2)),
                NotificationEntity(id: NotificationIDEntity(3))
            ],
            enabledNotifications: [1, 2]
        )
        
        await testFetchNotificationList(
            sut: sut,
            expectedPromoListCount: 2
        )
    }
    
    func testFetchNotificationList_whenEnabledNotificationsChange_notificationsShouldBeUpdated() async {
        let (sut, notificationsUseCase, _) = makeSUT(
            notifications: [
                NotificationEntity(id: NotificationIDEntity(1)),
                NotificationEntity(id: NotificationIDEntity(2)),
                NotificationEntity(id: NotificationIDEntity(3))
            ],
            enabledNotifications: [1, 2]
        )

        await testFetchNotificationList(
            sut: sut,
            expectedPromoListCount: 2
        )
        
        notificationsUseCase.enabledNotifications = [1, 2, 3]
        
        await testFetchNotificationList(
            sut: sut,
            expectedPromoListCount: 3
        )
    }
    
    func testFetchNotificationList_shouldBeSortedByHighestToLowestID() async {
        let (sut, _, _) = makeSUT(
            notifications: [
                NotificationEntity(id: NotificationIDEntity(1)),
                NotificationEntity(id: NotificationIDEntity(2)),
                NotificationEntity(id: NotificationIDEntity(3))
            ],
            enabledNotifications: [1, 2, 3]
        )
        
        await testFetchNotificationList(
            sut: sut,
            expectedPromoListCount: 3
        )
        
        XCTAssertEqual(sut.promoList.map(\.id), [3, 2, 1])
    }
    
    func testDoCurrentAndEnabledNotificationsDiffer_currentAndEnabledMatch_shouldReturnFalse() async {
        let (sut, _, _) = makeSUT(
            notifications: [
                NotificationEntity(id: NotificationIDEntity(1)),
                NotificationEntity(id: NotificationIDEntity(2))
            ],
            enabledNotifications: [1, 2]
        )
        
        await testFetchNotificationList(
            sut: sut,
            expectedPromoListCount: 2
        )
        
        XCTAssertFalse(sut.doCurrentAndEnabledNotificationsDiffer())
    }

    func testDoCurrentAndEnabledNotificationsDiffer_whenBothHaveDifferentNotifications_shouldReturnTrue() async {
        let (sut, notificationsUseCase, _) = makeSUT(
            notifications: [
                NotificationEntity(id: NotificationIDEntity(1)),
                NotificationEntity(id: NotificationIDEntity(2))
            ],
            enabledNotifications: [1, 2]
        )

        await testFetchNotificationList(
            sut: sut,
            expectedPromoListCount: 2
        )
        
        notificationsUseCase.enabledNotifications = [1]
        
        XCTAssertTrue(sut.doCurrentAndEnabledNotificationsDiffer())
    }
    
    func testUpdateLastReadNotificationId_shouldUpdateLastReadId() async throws {
        let expectedLastReadId = NotificationIDEntity(3)
        let (sut, notificationsUseCase, _) = makeSUT(
            notifications: [
                NotificationEntity(id: NotificationIDEntity(1)),
                NotificationEntity(id: NotificationIDEntity(2)),
                NotificationEntity(id: expectedLastReadId)
            ],
            enabledNotifications: [1, 2, expectedLastReadId],
            unreadNotificationIds: [1, 2, expectedLastReadId]
        )
        
        let exp = expectation(description: "Notifications are updated when feature is enabled and notifications are available.")
        sut.invokeCommand = { _ in
            exp.fulfill()
        }
        sut.dispatch(.onViewDidAppear)
        await fulfillment(of: [exp], timeout: 1.0)
        let lastReadNotifId = try await notificationsUseCase.fetchLastReadNotification()
        
        XCTAssertEqual(lastReadNotifId, expectedLastReadId)
    }
 func testDidTapNotification_whenNotificationTapped_presentRedirectionURLLink() {
        let (sut, _, _) = makeSUT()
        let expectedURL = URL(string: "http://test")!
        let testNotification = NotificationEntity(
            id: NotificationIDEntity(1),
            firstCallToAction: NotificationEntity.CallToAction(text: "Test", link: expectedURL)
        ).toNotificationItem(isSeen: true)
        
        test(
            viewModel: sut,
            action: NotificationAction.didTapNotification(testNotification),
            expectedCommands: [.presentURLLink(expectedURL)]
        )
    }
     func testClearImageCache_whenActionDispatched_cacheIsCleared() async {
        let imageLoader = ImageLoader()
        let (sut, _, _) = makeSUT(imageLoader: imageLoader)

        sut.dispatch(.clearImageCache)
        
        let isCacheClear = await imageLoader.isCacheClear
        
        XCTAssertTrue(isCacheClear, "Cache should be cleared when clearImageCache action is dispatched.")
    }
     func testClearCache_whenCalled_shouldIncrementClearCacheCallCount() async {
        let imageLoader = MockImageLoader()
        let (sut, _, _) = makeSUT(imageLoader: imageLoader)
        
        sut.dispatch(.clearImageCache)
        
        try? await Task.sleep(nanoseconds: 100_000_000)
        let clearCacheCallCount = await imageLoader.clearCacheCallCount
        
        XCTAssertEqual(clearCacheCallCount, 1, "Clear cache call count should be incremented")
    }
    
    private func testFetchNotificationList(
        sut: NotificationsViewModel,
        expectedPromoListCount: Int,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        let exp = expectation(description: "Notifications are updated when feature is enabled and notifications are available.")
        sut.invokeCommand = { commandReceived in
            exp.fulfill()
            XCTAssertEqual(commandReceived, .reloadData, file: file, line: line)
        }
        
        sut.dispatch(.onViewDidLoad)
        await fulfillment(of: [exp], timeout: 1.0)
        
        XCTAssertEqual(sut.promoList.count, expectedPromoListCount, file: file, line: line)
    }
    
    func testSharedItemNotificationMessage_withFilesOnly_shouldReturnCorrectMessage() {
        let fileCount = randomItemCount
        
        assertSharedItemNotificationMessage(
            fileCount: fileCount,
            expectedMessage: Strings.Localizable.Notifications.Message.SharedItems.filesOnly(fileCount)
        )
    }
    
    func testSharedItemNotificationMessage_withFoldersOnly_shouldReturnCorrectMessage() {
        let folderCount = randomItemCount
 
        assertSharedItemNotificationMessage(
            folderCount: folderCount,
            expectedMessage: Strings.Localizable.Notifications.Message.SharedItems.foldersOnly(folderCount)
        )
    }
    
    func testSharedItemNotificationMessage_withFileAndFolders_shouldReturnCorrectMessage() {
        let folderCount = randomItemCount
        let fileCount = randomItemCount

        assertSharedItemNotificationMessage(
            folderCount: folderCount,
            fileCount: fileCount,
            expectedMessage: Strings.Localizable.Notifications.Message.SharedItems.FilesAndfolders.files(fileCount) + " " +  Strings.Localizable.Notifications.Message.SharedItems.FilesAndfolders.folders(folderCount)
        )
    }
    
    func testOnViewDidAppear_shouldTrackNotificationCentreEvent() {
        let mockTracker = MockTracker()
        let (sut, _, _) = makeSUT(tracker: mockTracker)
        
        sut.dispatch(.onViewDidLoad)
        
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: mockTracker.trackedEventIdentifiers,
            with: [NotificationCentreScreenEvent()]
        )
    }
        
    func testDidTapNotification_shouldTrackNotificationCentreItemTapped() {
        let mockTracker = MockTracker()
        let (sut, _, _) = makeSUT(tracker: mockTracker)
        let testNotification = NotificationEntity(
            id: NotificationIDEntity(1),
            firstCallToAction: NotificationEntity.CallToAction(text: "Test", link: URL(string: "http://test")!)
        ).toNotificationItem(isSeen: true)
        
        sut.dispatch(.didTapNotification(testNotification))
        
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: mockTracker.trackedEventIdentifiers,
            with: [NotificationCentreItemTappedEvent()]
        )
    }
    
    func testHandleNodeNavigation_withNodeNotFound_shouldNotTriggerNavigation() async {
        let nonExistentHandle = HandleEntity(123)
        
        let (sut, _, router) = makeSUT()
        
        sut.dispatch(.handleNodeNavigation(nonExistentHandle))
        await Task.yield()
        
        XCTAssertEqual(router.navigateThroughNodeHierarchy_calledTimes, 0)
        XCTAssertEqual(router.navigateThroughNodeHierarchyAndPresent_calledTimes, 0)
    }
    
    func testHandleNodeNavigation_withTakenDownNode_shouldNavigateHierarchy() async {
        let parentNode = makeNode(
            nodeType: .rubbish,
            handle: parentHandle
        )
        let takenDownNode = makeNode(
            nodeType: .rubbish,
            handle: nodeHandle,
            parentHandle: parentNode.handle,
            isTakeDown: true
        )
        let (sut, _, router) = makeSUT(nodes: [parentNode, takenDownNode])
        
        sut.dispatch(.handleNodeNavigation(takenDownNode.handle))
        await sut.handleNodeNavigationTask?.value
        
        XCTAssertEqual(router.navigateThroughNodeHierarchy_calledTimes, 1)
        XCTAssertEqual(router.navigateThroughNodeHierarchyAndPresent_calledTimes, 0)
    }
    
    func testHandleNodeNavigation_withNormalNode_shouldPresentNodeDirectly() async {
        let parentNode = makeNode(
            nodeType: .folder,
            handle: parentHandle
        )
        let node = makeNode(
            nodeType: .file,
            handle: nodeHandle,
            parentHandle: parentNode.handle
        )
        
        let (sut, _, router) = makeSUT(nodes: [parentNode, node])
        
        sut.dispatch(.handleNodeNavigation(node.handle))
        await sut.handleNodeNavigationTask?.value
        
        XCTAssertEqual(router.navigateThroughNodeHierarchy_calledTimes, 0)
        XCTAssertEqual(router.navigateThroughNodeHierarchyAndPresent_calledTimes, 1)
    }
    
    private func assertSharedItemNotificationMessage(
        folderCount: Int = 0,
        fileCount: Int = 0,
        expectedMessage: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let (sut, _, _) = makeSUT()
        XCTAssertEqual(sut.sharedItemNotificationMessage(folderCount: folderCount, fileCount: fileCount), expectedMessage, file: file, line: line)
    }
    
    private func makeSUT(
        lastReadNotification: NotificationIDEntity = NotificationIDEntity(0),
        notifications: [NotificationEntity] = [],
        nodes: [NodeEntity]? = nil,
        enabledNotifications: [NotificationIDEntity] = [],
        unreadNotificationIds: [NotificationIDEntity] = [],
        imageLoader: some ImageLoadingProtocol = ImageLoader(),
        tracker: some AnalyticsTracking = MockTracker(),
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (NotificationsViewModel, MockNotificationUseCase, MockNotificationsViewRouter) {
        let mockNotificationsUseCase = MockNotificationUseCase(
            lastReadNotification: lastReadNotification,
            enabledNotifications: enabledNotifications,
            notifications: notifications,
            unreadNotificationIDs: unreadNotificationIds
        )
        
        let mockNodeUseCase: MockNodeUseCase
        
        if let nodes {
            let nodeDictionary = nodes.reduce(into: [:]) { $0[$1.handle] = $1 }
            mockNodeUseCase = MockNodeUseCase(nodes: nodeDictionary)
        } else {
            mockNodeUseCase = MockNodeUseCase()
        }
        
        let router = MockNotificationsViewRouter()
        
        let sut = NotificationsViewModel(
            router: router,
            notificationsUseCase: mockNotificationsUseCase,
            nodeUseCase: mockNodeUseCase,
            imageLoader: imageLoader,
            tracker: tracker
        )
        
        return (sut, mockNotificationsUseCase, router)
    }
    
    private var randomItemCount: Int {
        Int.random(in: 1...10)
    }
    
    private func makeNode(
        nodeType: NodeTypeEntity,
        handle: HandleEntity,
        parentHandle: HandleEntity = .invalid,
        isTakeDown: Bool = false
    ) -> NodeEntity {
        NodeEntity(
            nodeType: nodeType,
            handle: handle,
            parentHandle: parentHandle,
            isTakenDown: isTakeDown
        )
    }
}
