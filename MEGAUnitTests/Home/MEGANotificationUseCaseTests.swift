@testable import MEGA
import MEGADomain
import MEGADomainMock
import XCTest

class MEGANotificationUseCaseTests: XCTestCase {

    func testLoadNotification() throws {

        let notificationUseCase = MEGANotificationUseCase(userAlertsClient: .foundAlerts)
        let userAlerts = try XCTUnwrap(notificationUseCase.relevantAndNotSeenAlerts())
        XCTAssertEqual(userAlerts.count, 3)

        let contactRequests = notificationUseCase.incomingContactRequest()
        XCTAssertEqual(contactRequests.count, 2)
    }
}

extension SDKUserAlertsClient {

    static var doNothing: Self {
        return Self.init(notification: {
            return nil
        }, contactRequest: {
            return []
        }, userAlertsUpdate: { _ in

        }, incomingContactRequestUpdate: { _ in

        }, cleanup: {
            
        })
    }

    static var foundAlerts: Self {

        return Self.init(notification: { () -> [UserAlertEntity]? in
            let setRelevant = set(\UserAlertEntity.isRelevant, true)
            let setIrrelevant = set(\UserAlertEntity.isRelevant, false)
            let setNotSeen = set(\UserAlertEntity.isSeen, false)
            let setSeen = set(\UserAlertEntity.isSeen, true)

            return [
                setRelevant(setNotSeen(.random)),
                setRelevant(setNotSeen(.random)),
                setRelevant(setNotSeen(.random)),

                setIrrelevant(.random),
                setSeen(.random),
                setIrrelevant(setSeen(.random)),
                setIrrelevant(setNotSeen(.random))
            ]

        }, contactRequest: { () -> [ContactRequestEntity] in
            return [
                .random,
                .random
            ]
        }, userAlertsUpdate: { _ in

        }, incomingContactRequestUpdate: { _ in

        }, cleanup: {
        
        })
    }
}
