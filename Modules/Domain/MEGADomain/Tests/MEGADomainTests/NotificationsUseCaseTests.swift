import MEGADomain
import MEGADomainMock
import XCTest

final class NotificationsUseCaseTests: XCTestCase {
    private let defaultNotificationID = NotificationIDEntity(1)
    private let newReadNotificationID = NotificationIDEntity(2)
    
    func testFetchLastReadNotification_shouldReturnCorrectID() async throws {
        let sut = NotificationsUseCase(repository: MockNotificationsRepository(lastReadNotification: defaultNotificationID))
        
        let lastReadNotification = try await sut.fetchLastReadNotification()
        
        XCTAssertEqual(defaultNotificationID, lastReadNotification)
    }
    
    func testUpdateLastReadNotification_shouldUpdateLastReadNotificationID() async throws {
        let sut = NotificationsUseCase(repository: MockNotificationsRepository(lastReadNotification: defaultNotificationID))
        
        try await sut.updateLastReadNotification(notificationId: newReadNotificationID)
        let lastReadNotification = try await sut.fetchLastReadNotification()
        
        XCTAssertEqual(lastReadNotification, newReadNotificationID)
    }
    
    func testFetchEnabledNotifications_shouldReturnCorrectNotifications() {
        let expectedEnabledNotifications: [NotificationIDEntity] = [1, 2, 3]
        let sut = NotificationsUseCase(repository: MockNotificationsRepository(enabledNotifications: expectedEnabledNotifications))
        
        let enabledNotifications = sut.fetchEnabledNotifications()
        
        XCTAssertEqual(expectedEnabledNotifications, enabledNotifications)
    }
}
