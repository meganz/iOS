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
    case didTapNotification(NotificationItem)
}

@objc final class NotificationsViewModel: NSObject, ViewModelType {
    enum Command: CommandType, Equatable {
        case reloadData
        case presentURLLink(URL)
    }
    
    private let featureFlagProvider: any FeatureFlagProviderProtocol
    private let notificationsUseCase: any NotificationsUseCaseProtocol
    private(set) var promoList: [NotificationItem] = []
    private var unreadNotificationIds: [NotificationIDEntity] = []
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
    
    // MARK: - Setup
    private func setupNotifications() {
        Task { [weak self] in
            guard let self else { return }
            
            unreadNotificationIds = await notificationsUseCase.unreadNotificationIDs()
            await fetchPromoList()
        }
    }
    
    private func updateNotificationStates() {
        Task { [weak self] in
            guard let self else { return }
            
            if doCurrentAndEnabledNotificationsDiffer() {
                await fetchPromoList()
            }
            
            await updateLastReadNotificationId()
        }
    }
    
    private func fetchPromoList() async {
        guard isPromoEnabled else {
            promoList = []
            invokeCommand?(.reloadData)
            return
        }
        
        do {
            let userNotifications = try await notificationsUseCase.fetchNotifications()
            let filteredNotifications = filterEnabledNotifications(from: userNotifications)
            guard filteredNotifications.isNotEmpty else { return }
            
            promoList = filteredNotifications.toNotificationItems(withUnreadIDs: unreadNotificationIds)
            
            invokeCommand?(.reloadData)
        } catch {
            MEGALogError("[Notifications] Fetching notifications with error \(error.localizedDescription)")
        }
    }
    
    private func updateLastReadNotificationId() async {
        do {
            let unreadIds = await notificationsUseCase.unreadNotificationIDs()
            guard unreadIds.isNotEmpty, let highestId = unreadIds.max() else { return }
            
            try await notificationsUseCase.updateLastReadNotification(notificationId: highestId)
        } catch {
            MEGALogError("[Notifications] Updating last read notification with error \(error.localizedDescription)")
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
            setupNotifications()
        case .onViewDidAppear:
            updateNotificationStates()
        case .didTapNotification(let notification):
            guard isPromoEnabled, let urlLink = notification.redirectionURL else { return }
            invokeCommand?(.presentURLLink(urlLink))
        }
    }
}
