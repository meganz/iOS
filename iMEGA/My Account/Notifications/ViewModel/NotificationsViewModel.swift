import Foundation
import MEGADesignToken
import MEGADomain
import MEGAPresentation
import Notifications

@objc enum NotificationSection: Int {
    case promos = 0, userAlerts
}

enum NotificationAction: ActionType {
    case onViewDidLoad
}

@objc final class NotificationsViewModel: NSObject, ViewModelType {
    enum Command: CommandType, Equatable {
        case reloadData
    }
    
    private let featureFlagProvider: any FeatureFlagProviderProtocol
    private let notificationsUseCase: any NotificationsUseCaseProtocol
    private(set) var promoList: [NotificationItem] = []
    
    var invokeCommand: ((Command) -> Void)?
    
    init(
        featureFlagProvider: some FeatureFlagProviderProtocol,
        notificationsUseCase: some NotificationsUseCaseProtocol
    ) {
        self.featureFlagProvider = featureFlagProvider
        self.notificationsUseCase = notificationsUseCase
        super.init()
    }
    
    // MARK: - Feature flag
    @objc var isPromoEnabled: Bool {
        featureFlagProvider.isFeatureFlagEnabled(for: .notificationCenter)
    }
    
    // MARK: - Sections
    @objc var numberOfSections: Int {
        // With Promos - Section 0: Promos, Section 1: User Alerts
        // No Promos - Section 0: User Alerts
        isPromoEnabled ? 2 : 1
    }
    
    @objc var promoSectionNumberOfRows: Int {
        promoList.count
    }
    
    func fetchPromoList() {
        Task {
            do {
                let userNotifications = try await notificationsUseCase.fetchNotifications()
                let filteredNotifications = filterEnabledNotifications(from: userNotifications)
                
                if filteredNotifications.isNotEmpty {
                    promoList = filteredNotifications.compactMap {$0.toNotificationItem()}
                    invokeCommand?(.reloadData)
                }
            } catch {
                debugPrint(error.localizedDescription)
            }
        }
    }
    
    private func filterEnabledNotifications(from notificationList: [NotificationEntity]) -> [NotificationEntity] {
        let enabledNotifications = notificationsUseCase.fetchEnabledNotifications()
        return notificationList.filter { enabledNotifications.contains($0.id) }
    }
    
    func dispatch(_ action: NotificationAction) {
        switch action {
        case .onViewDidLoad:
            fetchPromoList()
        }
    }
}
