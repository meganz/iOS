import Foundation
import MEGADomain

protocol MEGANotificationUseCaseProtocol {

    func relevantAndNotSeenAlerts() -> [UserAlertEntity]?

    func incomingContactRequest() -> [ContactRequest]

    func observeUserAlerts(with callback: @escaping () -> Void)

    func observeUserContactRequests(with callback: @escaping () -> Void)
}

final class MEGANotificationUseCase: MEGANotificationUseCaseProtocol {

    private let userAlertsClient: SDKUserAlertsClient
    
    init(userAlertsClient: SDKUserAlertsClient) {
        self.userAlertsClient = userAlertsClient
    }
    
    func relevantAndNotSeenAlerts() -> [UserAlertEntity]? {
        return userAlertsClient.notification()?.filter {
            $0.isRelevant && !$0.isSeen
        }
    }

    func incomingContactRequest() -> [ContactRequest] {
        userAlertsClient.contactRequest()
    }

    func observeUserAlerts(with callback: @escaping () -> Void) {
        userAlertsClient.userAlertsUpdate(callback)
    }

    func observeUserContactRequests(with callback: @escaping () -> Void) {
        userAlertsClient.incomingContactRequestUpdate(callback)
    }

    deinit {
        userAlertsClient.cleanup()
    }
}
