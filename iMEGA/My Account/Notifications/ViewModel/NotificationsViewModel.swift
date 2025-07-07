import Foundation
import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGADesignToken
import MEGADomain
import MEGAL10n
import MEGASwiftUI
import Notifications

@objc enum NotificationSection: Int {
    case promos = 0, userAlerts
}

enum NotificationAction: ActionType {
    case onViewDidLoad
    case onViewDidAppear
    case didTapNotification(NotificationItem)
    case clearImageCache
    case handleNodeNavigation(HandleEntity)
}

@objc final class NotificationsViewModel: NSObject, ViewModelType {
    enum Command: CommandType, Equatable {
        case reloadData
        case presentURLLink(URL)
    }
    
    private let notificationsUseCase: any NotificationsUseCaseProtocol
    private let nodeUseCase: any NodeUseCaseProtocol
    private(set) var promoList: [NotificationItem] = []
    private var unreadNotificationIds: [NotificationIDEntity] = []
    private let tracker: any AnalyticsTracking
    private let router: any NotificationsViewRouting
    private(set) var handleNodeNavigationTask: Task<Void, Never>?
    var invokeCommand: ((Command) -> Void)?
    let imageLoader: any ImageLoadingProtocol
    
    init(
        router: some NotificationsViewRouting,
        notificationsUseCase: some NotificationsUseCaseProtocol,
        nodeUseCase: some NodeUseCaseProtocol,
        imageLoader: some ImageLoadingProtocol,
        tracker: some AnalyticsTracking
    ) {
        self.router = router
        self.notificationsUseCase = notificationsUseCase
        self.nodeUseCase = nodeUseCase
        self.imageLoader = imageLoader
        self.tracker = tracker
        super.init()
    }
    
    deinit {
        handleNodeNavigationTask?.cancel()
    }
    
    // MARK: - Sections
    
    // Section 0: Promos, Section 1: User Alerts
    @objc let numberOfSections = 2
    
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
        do {
            let userNotifications = try await notificationsUseCase.fetchNotifications()
            let filteredNotifications = filterEnabledNotifications(from: userNotifications)
            guard filteredNotifications.isNotEmpty else { return }
            
            promoList = filteredNotifications.toNotificationItems(
                withUnreadIDs: unreadNotificationIds
            ).sorted(by: { $0.id > $1.id })
            
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
    /// It checks if there's any difference in the notifications themselves. If they
    /// don't match up, it means something's different.
    ///
    /// - Returns: True or false. True means the lists don't match—they have different notifications.
    ///   False means everything matches, and the
    ///   notifications on the screen are exactly the ones that should be there.
    func doCurrentAndEnabledNotificationsDiffer() -> Bool {
        let currentPromoIDs = Set(promoList.map(\.id))
        let enabledNotifications = Set(notificationsUseCase.fetchEnabledNotifications())
        
        return currentPromoIDs != enabledNotifications
    }
    
    private func filterEnabledNotifications(from notificationList: [NotificationEntity]) -> [NotificationEntity] {
        let enabledNotifications = notificationsUseCase.fetchEnabledNotifications()
        return notificationList.filter { enabledNotifications.contains($0.id) }
    }
    
    private func trackNotificationCentreScreenEvent() {
        tracker.trackAnalyticsEvent(with: NotificationCentreScreenEvent())
    }
    
    private func trackNotificationCentreItemTapped() {
        tracker.trackAnalyticsEvent(with: NotificationCentreItemTappedEvent())
    }
    
    private func imageLoaderClearCache() {
        Task {
            await imageLoader.clearCache()
        }
    }
    
    private func handleTakenDownNode(node: NodeEntity) async {
        guard let nodeHierarchy = await nodeUseCase.parentsForHandle(node.handle) else { return }
        let nodeAccess = nodeUseCase.nodeAccessLevel(nodeHandle: node.handle)
        
        router.navigateThroughNodeHierarchy(
            node.isFile ? nodeHierarchy : nodeHierarchy.dropLast(),
            isOwnNode: nodeAccess == .owner,
            isInRubbishBin: node.nodeType == .rubbish
        )
    }
    
    private func presentNode(node: NodeEntity) {
        router.navigateThroughNodeHierarchyAndPresent(node)
    }
    
    func dispatch(_ action: NotificationAction) {
        switch action {
        case .onViewDidLoad:
            trackNotificationCentreScreenEvent()
            setupNotifications()
        case .onViewDidAppear:
            updateNotificationStates()
        case .didTapNotification(let notification):
            guard let urlLink = notification.redirectionURL else { return }
            trackNotificationCentreItemTapped()
            invokeCommand?(.presentURLLink(urlLink))
        case .clearImageCache:
            imageLoaderClearCache()
        case .handleNodeNavigation(let handle):
            handleNodeNavigationTask?.cancel()
            handleNodeNavigationTask = Task { [weak self] in
                guard let self, let node = await nodeUseCase.nodeForHandle(handle) else { return }
                if node.isTakenDown {
                    await handleTakenDownNode(node: node)
                } else {
                    presentNode(node: node)
                }
            }
        }
    }
    
    @objc func sharedItemNotificationMessage(folderCount: Int, fileCount: Int) -> String {
        if folderCount >= 1 && fileCount >= 1 {
            // Added x file/s and x folder/s
            let fileString = Strings.Localizable.Notifications.Message.SharedItems.FilesAndfolders.files(fileCount)
            let folderString = Strings.Localizable.Notifications.Message.SharedItems.FilesAndfolders.folders(folderCount)
            return fileString + " " + folderString
        }
        
        if folderCount >= 1 {
            // Added x folder/s
            return Strings.Localizable.Notifications.Message.SharedItems.foldersOnly(folderCount)
        }
        
        // Added x file/s
        return Strings.Localizable.Notifications.Message.SharedItems.filesOnly(fileCount)
    }
}
