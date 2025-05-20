import Foundation
import MEGAAppSDKRepo
import MEGADomain
import MEGASwift

protocol MEGANotificationUseCaseProtocol: Sendable {
    var userAlertsUpdates: AnyAsyncSequence<Void> { get }
    var userContactRequestsUpdates: AnyAsyncSequence<Void> { get }
    
    func relevantAndNotSeenAlerts() -> [UserAlertEntity]?
    func incomingContactRequest() -> [ContactRequestEntity]
    func unreadNotificationIDs() async -> [NotificationIDEntity]
}

final class MEGANotificationUseCase: MEGANotificationUseCaseProtocol {
    private let userAlertsRepository: any UserAlertsRepositoryProtocol
    private let notificationsUseCase: any NotificationsUseCaseProtocol
    
    var userAlertsUpdates: AnyAsyncSequence<Void> {
        userAlertsRepository
            .userAlertsUpdates
            .map { _ in () }
            .eraseToAnyAsyncSequence()
    }
    
    var userContactRequestsUpdates: AnyAsyncSequence<Void> {
        userAlertsRepository
            .userContactRequestsUpdates
            .map { _ in () }
            .eraseToAnyAsyncSequence()
    }
    
    init(
        userAlertsRepository: some UserAlertsRepositoryProtocol,
        notificationsUseCase: some NotificationsUseCaseProtocol
    ) {
        self.userAlertsRepository = userAlertsRepository
        self.notificationsUseCase = notificationsUseCase
    }
    
    func relevantAndNotSeenAlerts() -> [UserAlertEntity]? {
        return userAlertsRepository.notification?.filter {
            $0.isRelevant && !$0.isSeen
        }
    }

    func incomingContactRequest() -> [ContactRequestEntity] {
        userAlertsRepository.incomingContactRequest
    }
    
    func unreadNotificationIDs() async -> [NotificationIDEntity] {
        await notificationsUseCase.unreadNotificationIDs()
    }
}
