import MEGADomain
import MEGASDKRepo
import MEGASDKRepoMock
import XCTest

final class NotificationsRepositoryTests: XCTestCase {

    func testFetchLastReadNotification_shouldReturnCorrectID() async throws {
        let expectedLastReadId: Int64 = 1
        let sut = NotificationsRepository(sdk: MockSdk(requestResult: .success(MockRequest(handle: 1, number: expectedLastReadId))))
        
        let lastReadNotification = try await sut.fetchLastReadNotification()
        
        XCTAssertEqual(lastReadNotification, NotificationIDEntity(expectedLastReadId))
    }
    
    func testUpdateLastReadNotification_shouldUpdateLastReadNotificationID() async throws {
        let expectedLastReadId = NotificationIDEntity(2)
        let mockSdk = MockSdk(
            requestResult: .success(MockRequest(handle: 1, number: Int64(expectedLastReadId))), 
            lastReadNotificationId: 1
        )
        let sut = NotificationsRepository(sdk: mockSdk)
        
        try await sut.updateLastReadNotification(notificationId: expectedLastReadId)
        let lastReadNotification = try await sut.fetchLastReadNotification()
        
        XCTAssertEqual(lastReadNotification, expectedLastReadId)
    }
    
    func testFetchEnabledNotifications_shouldReturnCorrectIDs() {
        let expectedEnabledNotifications: [NotificationIDEntity] = [1, 2, 3]
        let mockSdk = MockSdk(enabledNotificationIdList: MockIntegerList(list: [1, 2, 3]))
        
        let sut = NotificationsRepository(sdk: mockSdk)
        XCTAssertEqual(sut.fetchEnabledNotifications(), expectedEnabledNotifications)
    }
    
    func testFetchNotifications_whenApiOK_shouldReturnNotificationList() async throws {
        let mockRequest = MockRequest(
            handle: 1,
            notifications: MockNotificationList(
                notifications: [
                    MockNotification(identifier: 1),
                    MockNotification(identifier: 2),
                    MockNotification(identifier: 3)
                ]
            ))
        let sut = NotificationsRepository(sdk: MockSdk(requestResult: .success(mockRequest)))
        
        let list = try await sut.fetchNotifications()
        
        XCTAssertEqual(list, [NotificationEntity(id: 1), 
                              NotificationEntity(id: 2),
                              NotificationEntity(id: 3)])
    }
    
    func testFetchNotifications_whenApiError_shouldReturnError() async {
        let expectedError = MockError.failingError
        let sut = NotificationsRepository(sdk: MockSdk(requestResult: .failure(expectedError)))
        
        await XCTAsyncAssertThrowsError(try await sut.fetchNotifications()) { error in
            XCTAssertEqual(error as? MockError, expectedError)
        }
    }
}
