@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGASwift
import XCTest

class MEGANotificationUseCaseTests: XCTestCase {

    func testLoadNotification() throws {

        let notificationUseCase = MEGANotificationUseCase(userAlertsRepository: MockUserAlertsRepository.foundAlerts, notificationsUseCase: MockNotificationUseCase())
        let userAlerts = try XCTUnwrap(notificationUseCase.relevantAndNotSeenAlerts())
        XCTAssertEqual(userAlerts.count, 3)

        let contactRequests = notificationUseCase.incomingContactRequest()
        XCTAssertEqual(contactRequests.count, 2)
    }
    
    func testUnreadNotificationIDs_shouldReturnUnreadIDs() async {
        let expectedUnreadIDs = [NotificationIDEntity(1), NotificationIDEntity(2), NotificationIDEntity(3)]
        let sut = MEGANotificationUseCase(
            userAlertsRepository: MockUserAlertsRepository.foundAlerts,
            notificationsUseCase: MockNotificationUseCase(unreadNotificationIDs: expectedUnreadIDs)
        )
        
        let unreadIDs = await sut.unreadNotificationIDs()
        XCTAssertEqual(unreadIDs, expectedUnreadIDs)
    }
}

final class MockUserAlertsRepository: UserAlertsRepositoryProtocol {
    public static var newRepo: MockUserAlertsRepository {
        .doNothing
    }
    
    let userAlertsUpdates: AnyAsyncSequence<[UserAlertEntity]>
    let userContactRequestsUpdates: AnyAsyncSequence<[ContactRequestEntity]>
    let notification: [UserAlertEntity]?
    let incomingContactRequest: [ContactRequestEntity]
    
    init(
        userAlertsUpdates: AnyAsyncSequence<[UserAlertEntity]>,
        userContactRequestsUpdates: AnyAsyncSequence<[ContactRequestEntity]>,
        notification: [UserAlertEntity]?,
        contactRequest: [ContactRequestEntity]
    ) {
        self.userAlertsUpdates = userAlertsUpdates
        self.userContactRequestsUpdates = userContactRequestsUpdates
        self.notification = notification
        self.incomingContactRequest = contactRequest
    }
}

extension MockUserAlertsRepository {

    static var doNothing: Self {
        Self.init(
            userAlertsUpdates: EmptyAsyncSequence().eraseToAnyAsyncSequence(),
            userContactRequestsUpdates: EmptyAsyncSequence().eraseToAnyAsyncSequence(),
            notification: [],
            contactRequest: []
        )
    }

    static var foundAlerts: Self {
        let setRelevant = set(\UserAlertEntity.isRelevant, true)
        let setIrrelevant = set(\UserAlertEntity.isRelevant, false)
        let setNotSeen = set(\UserAlertEntity.isSeen, false)
        let setSeen = set(\UserAlertEntity.isSeen, true)
        let notification = [
            setRelevant(setNotSeen(.random)),
            setRelevant(setNotSeen(.random)),
            setRelevant(setNotSeen(.random)),
            setIrrelevant(.random),
            setSeen(.random),
            setIrrelevant(setSeen(.random)),
            setIrrelevant(setNotSeen(.random))
        ]
        let contactRequest: [ContactRequestEntity] = [.random, .random]
        
        return Self.init(
            userAlertsUpdates: EmptyAsyncSequence().eraseToAnyAsyncSequence(),
            userContactRequestsUpdates: EmptyAsyncSequence().eraseToAnyAsyncSequence(),
            notification: notification,
            contactRequest: contactRequest
        )
    }
}
