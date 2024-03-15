@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGAPresentation
import MEGAPresentationMock
import XCTest

final class NotificationsViewModelTests: XCTestCase {
    
    func testNumberOfSections_notificationsEnabled_twoSections() {
        let (sut, _) = makeSUT(featureFlagList: [.notificationCenter: true])
        XCTAssertEqual(sut.numberOfSections, 2)
    }
    
    func testNumberOfSections_notificationsDisabled_oneSection() {
        let (sut, _) = makeSUT()
        XCTAssertEqual(sut.numberOfSections, 1)
    }
    
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
    
    private func waitForCommand(
        on sut: NotificationsViewModel,
        expectedCommand: NotificationsViewModel.Command,
        description: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let expectation = XCTestExpectation(description: description)
        
        sut.invokeCommand = { commandReceived in
            expectation.fulfill()
            XCTAssertEqual(commandReceived, expectedCommand, file: file, line: line)
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    private func makeSUT(
        featureFlagList: [FeatureFlagKey: Bool] = [:],
        lastReadNotification: NotificationIDEntity = NotificationIDEntity(0),
        notifications: [NotificationEntity] = [],
        enabledNotifications: [NotificationIDEntity] = [],
        unreadNotificationIds: [NotificationIDEntity] = [],
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
            notificationsUseCase: mockNotificationsUseCase
        )
        
        trackForMemoryLeaks(on: sut, file: file, line: line)
        return (sut, mockNotificationsUseCase)
    }
}
