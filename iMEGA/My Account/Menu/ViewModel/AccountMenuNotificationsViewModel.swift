import AsyncAlgorithms
import MEGAAppSDKRepo
import MEGADomain
import MEGASwift

@MainActor
final class AccountMenuNotificationsViewModel {

    private let accountUseCase: any AccountUseCaseProtocol
    private let sharedItemsUseCase: any ShareUseCaseProtocol
    private let notificationsUseCase: any NotificationsUseCaseProtocol
    private let contactsUseCase: any ContactsUseCaseProtocol

    init(
        accountUseCase: some AccountUseCaseProtocol,
        sharedItemsUseCase: some ShareUseCaseProtocol,
        notificationsUseCase: some NotificationsUseCaseProtocol,
        contactsUseCase: some ContactsUseCaseProtocol
    ) {
        self.accountUseCase = accountUseCase
        self.sharedItemsUseCase = sharedItemsUseCase
        self.notificationsUseCase = notificationsUseCase
        self.contactsUseCase = contactsUseCase
    }

    var notificationBadgeValue: AnyAsyncSequence<String?> {
        makeNotificationsSequence()
            .map { $0 ? "" : nil }
            .eraseToAnyAsyncSequence()
    }

    private func makeNotificationsSequence() -> AnyAsyncSequence<Bool> {
        let userNotificationUpdates = accountUseCase.onUserAlertsUpdates
            .map { _ in return () }
            .eraseToAnyAsyncSequence()
        let contactUpdates = accountUseCase.onContactRequestsUpdates
            .map { _ in return () }
            .eraseToAnyAsyncSequence()

        return merge(userNotificationUpdates, contactUpdates)
            .map { [self] in
                let showsAccountNotifications = accountUseCase.incomingContactsRequestsCount() > 0 || accountUseCase.relevantUnseenUserAlertsCount() > 0

                async let showsUnreadNotifications = notificationsUseCase.unreadNotificationIDs().count > 0

                async let showUnverifiedInShares = sharedItemsUseCase.unverifiedInShares().count > 0

                async let showUnverifiedOutShares = sharedItemsUseCase.unverifiedOutShares().count > 0 && contactsUseCase.isContactVerificationWarningEnabled

                let asyncResults = await (showsAccountNotifications, showsUnreadNotifications, showUnverifiedInShares, showUnverifiedOutShares)
                return asyncResults.0 || asyncResults.1 || asyncResults.2 || asyncResults.3
            }
            .eraseToAnyAsyncSequence()
    }
}

extension AccountUseCaseProtocol {
    func calIncomingContactsRequestsCountAndRelevantUnseenUserAlertsCountLargerThanZero() async -> Bool {
        incomingContactsRequestsCount() > 0 || relevantUnseenUserAlertsCount() > 0
    }
}
