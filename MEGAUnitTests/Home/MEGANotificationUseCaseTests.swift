import XCTest
@testable import MEGA

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

        return Self.init(notification: { () -> [UserAlert]? in
            let setRelevant = set(\UserAlert.isRelevant, true)
            let setIrrelevant = set(\UserAlert.isRelevant, false)
            let setNotSeen = set(\UserAlert.isSeen, false)
            let setSeen = set(\UserAlert.isSeen, true)

            return [
                setRelevant(setNotSeen(.random)),
                setRelevant(setNotSeen(.random)),
                setRelevant(setNotSeen(.random)),

                setIrrelevant(.random),
                setSeen(.random),
                setIrrelevant(setSeen(.random)),
                setIrrelevant(setNotSeen(.random)),
            ]

        }, contactRequest: { () -> [ContactRequest] in
            return [
                .random,
                .random,
            ]
        }, userAlertsUpdate: { _ in

        }, incomingContactRequestUpdate: { _ in

        }, cleanup: {
        
        })
    }
}
