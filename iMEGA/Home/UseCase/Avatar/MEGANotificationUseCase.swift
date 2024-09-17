import Foundation
import MEGADomain

protocol MEGANotificationUseCaseProtocol: Sendable {

    func relevantAndNotSeenAlerts() -> [UserAlertEntity]?

    func incomingContactRequest() -> [ContactRequestEntity]

    func observeUserAlerts(with callback: @escaping () -> Void)

    func observeUserContactRequests(with callback: @escaping () -> Void)
    
    func unreadNotificationIDs() async -> [NotificationIDEntity]
}

final class MEGANotificationUseCase: MEGANotificationUseCaseProtocol {

    private let userAlertsClient: SDKUserAlertsClient
    
    private let notificationsUseCase: any NotificationsUseCaseProtocol
    
    init(
        userAlertsClient: SDKUserAlertsClient,
        notificationsUseCase: some NotificationsUseCaseProtocol
    ) {
        self.userAlertsClient = userAlertsClient
        self.notificationsUseCase = notificationsUseCase
    }
    
    func relevantAndNotSeenAlerts() -> [UserAlertEntity]? {
        return userAlertsClient.notification()?.filter {
            $0.isRelevant && !$0.isSeen
        }
    }

    func incomingContactRequest() -> [ContactRequestEntity] {
        userAlertsClient.contactRequest()
    }

    func observeUserAlerts(with callback: @escaping () -> Void) {
        userAlertsClient.userAlertsUpdate(callback)
    }

    func observeUserContactRequests(with callback: @escaping () -> Void) {
        userAlertsClient.incomingContactRequestUpdate(callback)
    }
    
    func unreadNotificationIDs() async -> [NotificationIDEntity] {
        await notificationsUseCase.unreadNotificationIDs()
    }

    deinit {
        userAlertsClient.cleanup()
    }
}
