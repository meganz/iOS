@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGAPresentation
import MEGAPresentationMock
import MEGASwiftUI
import Notifications
import XCTest

final class NotificationsViewModelTests: XCTestCase {
    
    func testNumberOfSections_notificationsEnabled_twoSections() {
        let (sut, _) = makeSUT(featureFlagList: [.notificationCenter: true])
        XCTAssertEqual(sut.numberOfSections, 2)
    }
    
    @MainActor
    func testNotificationsSectionNumberOfRows_notificationsEnabled_matchNotificationsCount() async {
        let (sut, _) = makeSUT(
            featureFlagList: [.notificationCenter: true],
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
            featureFlagList: [.notificationCenter: true],
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
            featureFlagList: [.notificationCenter: true],
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
            featureFlagList: [.notificationCenter: true],
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
            featureFlagList: [.notificationCenter: true],
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
            featureFlagList: [.notificationCenter: true],
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
        let (sut, _) = makeSUT(featureFlagList: [.notificationCenter: true])
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
        let (sut, _) = makeSUT(
            featureFlagList: [.notificationCenter: true],
            imageLoader: imageLoader
        )

        sut.dispatch(.clearImageCache)
        
        XCTAssertTrue(imageLoader.isCacheClear, "Cache should be cleared when clearImageCache action is dispatched.")
    }
    
    func testClearCache_whenCalled_shouldIncrementClearCacheCallCount() {
        let imageLoader = MockImageLoader()
        
        let (sut, _) = makeSUT(
            featureFlagList: [.notificationCenter: true],
            imageLoader: imageLoader
        )
        
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
    
    private func makeSUT(
        featureFlagList: [FeatureFlagKey: Bool] = [:],
        lastReadNotification: NotificationIDEntity = NotificationIDEntity(0),
        notifications: [NotificationEntity] = [],
        enabledNotifications: [NotificationIDEntity] = [],
        unreadNotificationIds: [NotificationIDEntity] = [],
        imageLoader: ImageLoadingProtocol = ImageLoader(),
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (NotificationsViewModel, MockNotificationUseCase) {
        let mockFeatureFlagProvider = MockFeatureFlagProvider(list: featureFlagList)
        let mockNotificationsUseCase = MockNotificationUseCase(
            lastReadNotification: lastReadNotification,
            enabledNotifications: enabledNotifications,
            notifications: notifications,
            unreadNotificationIDs: unreadNotificationIds
        )
        
        let sut = NotificationsViewModel(
            featureFlagProvider: mockFeatureFlagProvider,
            notificationsUseCase: mockNotificationsUseCase,
            imageLoader: imageLoader
        )
        
        trackForMemoryLeaks(on: sut, file: file, line: line)
        return (sut, mockNotificationsUseCase)
    }
}
