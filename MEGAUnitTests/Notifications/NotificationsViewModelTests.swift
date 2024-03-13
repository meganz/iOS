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
    
    func testNotificationsSectionNumberOfRows_notificationsEnabled_matchNotificationsCount() {
        let (sut, _) = makeSUT(
            featureFlagList: [.notificationCenter: true],
            notifications: [
                NotificationEntity(id: NotificationIDEntity(1)),
                NotificationEntity(id: NotificationIDEntity(2)),
                NotificationEntity(id: NotificationIDEntity(3))
            ],
            enabledNotifications: [1, 2]
        )
        
        testFetchNotificationList(
            sut: sut,
            expectedPromoListCount: 2
        )
    }
    
    func testFetchNotificationList_whenEnabledNotificationsChange_notificationsShouldBeUpdated() {
        let (sut, notificationsUseCase) = makeSUT(
            featureFlagList: [.notificationCenter: true],
            notifications: [
                NotificationEntity(id: NotificationIDEntity(1)),
                NotificationEntity(id: NotificationIDEntity(2)),
                NotificationEntity(id: NotificationIDEntity(3))
            ],
            enabledNotifications: [1, 2]
        )

        testFetchNotificationList(
            sut: sut,
            expectedPromoListCount: 2
        )
        
        notificationsUseCase.enabledNotifications = [1, 2, 3]
        
        testFetchNotificationList(
            sut: sut,
            expectedPromoListCount: 3
        )
    }
    
    func testDoCurrentAndEnabledNotificationsDiffer_currentAndEnabledMatch_shouldReturnFalse() {
        let (sut, _) = makeSUT(
            featureFlagList: [.notificationCenter: true],
            notifications: [
                NotificationEntity(id: NotificationIDEntity(1)),
                NotificationEntity(id: NotificationIDEntity(2))
            ],
            enabledNotifications: [1, 2]
        )
        
        testFetchNotificationList(
            sut: sut,
            expectedPromoListCount: 2
        )
        
        XCTAssertFalse(sut.doCurrentAndEnabledNotificationsDiffer())
    }

    func testDoCurrentAndEnabledNotificationsDiffer_whenBothHaveDifferentNotifications_shouldReturnTrue() {
        let (sut, notificationsUseCase) = makeSUT(
            featureFlagList: [.notificationCenter: true],
            notifications: [
                NotificationEntity(id: NotificationIDEntity(1)),
                NotificationEntity(id: NotificationIDEntity(2))
            ],
            enabledNotifications: [1, 2]
        )

        testFetchNotificationList(
            sut: sut,
            expectedPromoListCount: 2
        )
        
        notificationsUseCase.enabledNotifications = [1]
        
        XCTAssertTrue(sut.doCurrentAndEnabledNotificationsDiffer())
    }
    
    private func testFetchNotificationList(
        sut: NotificationsViewModel,
        expectedPromoListCount: Int,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        sut.fetchPromoList()
        
        waitForCommand(
            on: sut,
            expectedCommand: .reloadData,
            description: "Notifications are updated when feature is enabled and notifications are available."
        )
        
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
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (NotificationsViewModel, MockNotificationUseCase) {
        let mockFeatureFlagProvider = MockFeatureFlagProvider(list: featureFlagList)
        let mockNotificationsUseCase = MockNotificationUseCase(
            lastReadNotification: lastReadNotification,
            enabledNotifications: enabledNotifications,
            notifications: notifications
        )
        
        let sut = NotificationsViewModel(
            featureFlagProvider: mockFeatureFlagProvider,
            notificationsUseCase: mockNotificationsUseCase
        )
        
        trackForMemoryLeaks(on: sut, file: file, line: line)
        return (sut, mockNotificationsUseCase)
    }
}
