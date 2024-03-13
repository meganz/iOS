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
    case onViewDidAppear
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
                    promoList = filteredNotifications.toNotificationItems()
                    invokeCommand?(.reloadData)
                }
            } catch {
                debugPrint(error.localizedDescription)
            }
        }
    }
    
    /// Checks if the list of notifications currently shown and the enabled notifications differ.
    ///
    /// It checks if there's any difference in the notifications themselves or the order they appear in. If they
    /// don't match up exactly, it means something's different.
    ///
    /// - Returns: True or false. True means the lists don't match—they have different notifications or
    ///   the notifications are in a different order. False means everything matches perfectly, and the
    ///   notifications on the screen are exactly the ones that should be there.
    func doCurrentAndEnabledNotificationsDiffer() -> Bool {
        let currentPromoIDs: [NotificationID] = promoList.map(\.id)
        let enabledNotifications: [NotificationIDEntity] = notificationsUseCase.fetchEnabledNotifications()
        
        return currentPromoIDs != enabledNotifications
    }
    
    private func filterEnabledNotifications(from notificationList: [NotificationEntity]) -> [NotificationEntity] {
        let enabledNotifications = notificationsUseCase.fetchEnabledNotifications()
        return notificationList.filter { enabledNotifications.contains($0.id) }
    }
    
    func dispatch(_ action: NotificationAction) {
        switch action {
        case .onViewDidLoad:
            fetchPromoList()
        case .onViewDidAppear:
            if doCurrentAndEnabledNotificationsDiffer() {
                fetchPromoList()
            }
        }
    }
}
