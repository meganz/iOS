import MEGAAppSDKRepo
import MEGAAppSDKRepoMock
import MEGADomain
import XCTest

final class NotificationsRepositoryTests: XCTestCase {

    func testFetchLastReadNotification_shouldReturnCorrectID() async throws {
        let expectedLastReadId: Int64 = 1
        let sut = makeSUT(
            requestResult: .success(MockRequest(handle: 1, number: expectedLastReadId))
        )
        
        let lastReadNotification = try await sut.fetchLastReadNotification()
        
        XCTAssertEqual(lastReadNotification, NotificationIDEntity(expectedLastReadId))
    }
    
    func testUpdateLastReadNotification_shouldUpdateLastReadNotificationID() async throws {
        let expectedLastReadId = NotificationIDEntity(2)
        let sut = makeSUT(
            requestResult: .success(MockRequest(handle: 1, number: Int64(expectedLastReadId))),
            lastReadNotificationId: 1
        )
        
        try await sut.updateLastReadNotification(notificationId: expectedLastReadId)
        let lastReadNotification = try await sut.fetchLastReadNotification()
        
        XCTAssertEqual(lastReadNotification, expectedLastReadId)
    }
    
    func testFetchEnabledNotifications_shouldReturnCorrectIDs() {
        let sut = makeSUT(enabledNotificationIdList: [1, 2, 3])
        
        XCTAssertEqual(sut.fetchEnabledNotifications(), [NotificationIDEntity(1),
                                                         NotificationIDEntity(2),
                                                         NotificationIDEntity(3)])
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
        let sut = makeSUT(requestResult: .success(mockRequest))
        
        let list = try await sut.fetchNotifications()
        
        XCTAssertEqual(list, [NotificationEntity(id: 1), 
                              NotificationEntity(id: 2),
                              NotificationEntity(id: 3)])
    }
    
    func testFetchNotifications_whenApiError_shouldReturnError() async {
        let expectedError = MockError(errorType: .anyFailingErrorType)
        let sut = makeSUT(requestResult: .failure(expectedError))
        
        await XCTAsyncAssertThrowsError(try await sut.fetchNotifications()) { error in
            XCTAssertEqual(error as? MockError, expectedError)
        }
    }
    
    func testUnreadNotificationIDs_successLastReadNotificationRequest_withValidID_shouldReturnUnreadIDs() async {
        let lastReadNotifID: Int64 = 1
        let sut = makeSUT(
            // For fetchLastReadNotification with valid ID
            requestResult: .success(MockRequest(handle: 1, number: lastReadNotifID)),
            // For fetchEnabledNotifications
            enabledNotificationIdList: [1, 2, 3]
        )
        
        let unreadIDs = await sut.unreadNotificationIDs()
        
        XCTAssertEqual(unreadIDs, [NotificationIDEntity(2), NotificationIDEntity(3)])
    }
    
    func testUnreadNotificationIDs_successLastReadNotificationRequest_withInvalidID_shouldReturnAllEnabledNotifIDs() async {
        let lastReadNotifID: Int64 = 0
        let sut = makeSUT(
            // For fetchLastReadNotification with invalid ID
            requestResult: .success(MockRequest(handle: 1, number: lastReadNotifID)),
            // For fetchEnabledNotifications
            enabledNotificationIdList: [1, 2, 3]
        )
        
        let unreadIDs = await sut.unreadNotificationIDs()
        
        XCTAssertEqual(unreadIDs, [NotificationIDEntity(1), NotificationIDEntity(2), NotificationIDEntity(3)])
    }
    
    func testUnreadNotificationIDs_failedLastReadNotificationRequest_withErrorApiENoent_shouldReturnAllEnabledNotifIDs() async {
        let sut = makeSUT(
            // For fetchLastReadNotification. No last read notif.
            requestResult: .failure(MockError(errorType: .apiENoent)),
            // For fetchEnabledNotifications
            enabledNotificationIdList: [1, 2, 3]
        )
        
        let unreadIDs = await sut.unreadNotificationIDs()
        
        XCTAssertEqual(unreadIDs, [NotificationIDEntity(1), NotificationIDEntity(2), NotificationIDEntity(3)])
    }
    
    func testUnreadNotificationIDs_failedLastReadNotificationRequest_withErrorOtherThanApiENoent_shouldNotReturnAnyID() async {
        let sut = makeSUT(
            // For fetchLastReadNotification. Failed last read notif.
            requestResult: .failure(MockError(errorType: .apiEAccess)),
            // For fetchEnabledNotifications
            enabledNotificationIdList: [1, 2, 3]
        )
        
        let unreadIDs = await sut.unreadNotificationIDs()
        
        XCTAssertEqual(unreadIDs, [])
    }
    
    // MARK: - Helper
    
    private func makeSUT(
        requestResult: MockSdkRequestResult = .failure(MockError()),
        enabledNotificationIdList: [Int64] = [],
        lastReadNotificationId: Int32 = 1,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> NotificationsRepository {
        let mockSdk = MockSdk(
            requestResult: requestResult,
            enabledNotificationIdList: MockIntegerList(list: enabledNotificationIdList),
            lastReadNotificationId: lastReadNotificationId
        )
        return NotificationsRepository(sdk: mockSdk)
    }
}
