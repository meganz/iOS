@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGAL10n
import MEGAPresentation
import MEGAPresentationMock
import MEGASwiftUI
import Notifications
import XCTest

final class NotificationsViewModelTests: XCTestCase {
    
    func testNumberOfSections_shouldBeTwoSections() {
        let (sut, _) = makeSUT()
        XCTAssertEqual(sut.numberOfSections, 2)
    }
    
    @MainActor
    func testNotificationsSectionNumberOfRows_shouldMatchNotificationsCount() async {
        let (sut, _) = makeSUT(
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
    
    @MainActor
    func testFetchNotificationList_whenEnabledNotificationsChange_notificationsShouldBeUpdated() async {
        let (sut, notificationsUseCase) = makeSUT(
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
    
    @MainActor
    func testFetchNotificationList_shouldBeSortedByHighestToLowestID() async {
        let (sut, _) = makeSUT(
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
    
    @MainActor
    func testDoCurrentAndEnabledNotificationsDiffer_currentAndEnabledMatch_shouldReturnFalse() async {
        let (sut, _) = makeSUT(
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

    @MainActor
    func testDoCurrentAndEnabledNotificationsDiffer_whenBothHaveDifferentNotifications_shouldReturnTrue() async {
        let (sut, notificationsUseCase) = makeSUT(
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
    
    @MainActor
    func testUpdateLastReadNotificationId_shouldUpdateLastReadId() async throws {
        let expectedLastReadId = NotificationIDEntity(3)
        let (sut, notificationsUseCase) = makeSUT(
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

    @MainActor func testDidTapNotification_whenNotificationTapped_presentRedirectionURLLink() {
        let (sut, _) = makeSUT()
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
    
    func testClearImageCache_whenActionDispatched_cacheIsCleared() {
        let imageLoader = ImageLoader()
        let (sut, _) = makeSUT(imageLoader: imageLoader)

        sut.dispatch(.clearImageCache)
        
        XCTAssertTrue(imageLoader.isCacheClear, "Cache should be cleared when clearImageCache action is dispatched.")
    }
    
    func testClearCache_whenCalled_shouldIncrementClearCacheCallCount() {
        let imageLoader = MockImageLoader()
        
        let (sut, _) = makeSUT(imageLoader: imageLoader)
        
        sut.dispatch(.clearImageCache)

        XCTAssertEqual(imageLoader.clearCacheCallCount, 1, "Clear cache call count should be incremented")
    }
    
    @MainActor
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
    
    private func assertSharedItemNotificationMessage(
        folderCount: Int = 0,
        fileCount: Int = 0,
        expectedMessage: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let (sut, _) = makeSUT()
        XCTAssertEqual(sut.sharedItemNotificationMessage(folderCount: folderCount, fileCount: fileCount), expectedMessage, file: file, line: line)
    }
    
    private func makeSUT(
        lastReadNotification: NotificationIDEntity = NotificationIDEntity(0),
        notifications: [NotificationEntity] = [],
        enabledNotifications: [NotificationIDEntity] = [],
        unreadNotificationIds: [NotificationIDEntity] = [],
        imageLoader: some ImageLoadingProtocol = ImageLoader(),
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (NotificationsViewModel, MockNotificationUseCase) {
        let mockNotificationsUseCase = MockNotificationUseCase(
            lastReadNotification: lastReadNotification,
            enabledNotifications: enabledNotifications,
            notifications: notifications,
            unreadNotificationIDs: unreadNotificationIds
        )
        
        let sut = NotificationsViewModel(
            notificationsUseCase: mockNotificationsUseCase,
            imageLoader: imageLoader
        )
        
        trackForMemoryLeaks(on: sut, file: file, line: line)
        return (sut, mockNotificationsUseCase)
    }
    
    private var randomItemCount: Int {
        Int.random(in: 1...10)
    }
}
