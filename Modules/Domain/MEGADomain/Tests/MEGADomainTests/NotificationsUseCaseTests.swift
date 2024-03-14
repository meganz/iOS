import MEGADomain
import MEGADomainMock
import MEGATest
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
    
    func testFetchNotifications_whenSuccess_shouldReturnCorrectNotifications() async throws {
        let expectedNotifications = [NotificationEntity(id: 1),
                                     NotificationEntity(id: 2),
                                     NotificationEntity(id: 3)]
        let mockRepo = MockNotificationsRepository(notificationsResult: .success(expectedNotifications))
        let sut = NotificationsUseCase(repository: mockRepo)
        
        let notifications = try await sut.fetchNotifications()
        
        XCTAssertEqual(notifications, expectedNotifications)
    }
    
    func testFetchNotifications_whenFailed_shouldReturnError() async {
        let mockRepo = MockNotificationsRepository(notificationsResult: .failure(GenericErrorEntity()))
        let sut = NotificationsUseCase(repository: mockRepo)
        
        await XCTAsyncAssertThrowsError(try await sut.fetchNotifications())
    }
    
    func testUnreadNotificationIDs_shouldReturnCorrectUnreadIDs() async {
        let expectedUnreadIDs: [NotificationIDEntity] = [1, 2, 3]
        let mockRepo = MockNotificationsRepository(unreadNotificationIDs: expectedUnreadIDs)
        let sut = NotificationsUseCase(repository: mockRepo)
        
        let unreadIDs = await sut.unreadNotificationIDs()
        
        XCTAssertEqual(unreadIDs, expectedUnreadIDs)
    }
}
