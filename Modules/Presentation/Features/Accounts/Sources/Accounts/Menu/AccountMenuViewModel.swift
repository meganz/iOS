import Combine
import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGAAssets
import MEGADesignToken
import MEGADomain
import MEGAL10n
import MEGAPreference
import MEGASwift
import MEGAUIKit
import SwiftUI

public enum MegaCompanionApp {
    case vpn
    case passwordManager
    case transferIt

    public var link: String {
        switch self {
        case .vpn: "https://vpn.mega.nz"
        case .passwordManager: "https://pwm.mega.nz"
        case .transferIt: "https://transfer.it"
        }
    }
}

@MainActor
public protocol AccountMenuViewRouting {
    func showNotifications()
    func showAccount()
    func upgradeAccount()
    func showStorage()
    func showContacts()
    func showAchievements()
    func showSharedItems()
    func showDeviceCentre()
    func showTransfers()
    func showOfflineFiles()
    func showRubbishBin()
    func showSettings()
    func openLink(for app: MegaCompanionApp)
}

@MainActor
public final class AccountMenuViewModel: ObservableObject {
    enum Constants {
        /// How far the scroll view can move from the top before it's no longer considered "at the top".
        ///
        /// If the scroll position (after adjusting for any top inset) is less than this value,
        /// the `isAtTop` value will be set to `true`.
        ///
        /// This helps handle small scroll movements or bouncing without losing the "at top" state.
        static let topOffsetThreshold: CGFloat = 5

        static let coordinateSpaceName = "Scroll"
    }

    @Published var isPrivacySuiteExpanded = false
    @Published private(set) var sections: [AccountMenuSectionType: [AccountMenuOption]] = [:]
    @Published var appNotificationsCount = 0
    @Published var isAtTop = true

    private let router: any AccountMenuViewRouting
    private let tracker: any AnalyticsTracking
    private let accountUseCase: any AccountUseCaseProtocol
    private let currentUserSource: CurrentUserSource
    private let userImageUseCase: any UserImageUseCaseProtocol
    private let megaHandleUseCase: any MEGAHandleUseCaseProtocol
    private let networkMonitorUseCase: any NetworkMonitorUseCaseProtocol
    private var monitorTask: Task<Void, Never>?
    private let fullNameHandler: (CurrentUserSource) -> String
    private let avatarFetchHandler: (String, HandleEntity) async -> UIImage?
    private let logoutHandler: () async -> Void
    private let sharedItemsNotificationCountHandler: () -> Int

    @PreferenceWrapper(key: PreferenceKeyEntity.offlineLogOutWarningDismissed, defaultValue: false)
    private var offlineLogOutWarningDismissed: Bool

    private var cancelTransfersTask: Task<Void, Never>? {
        didSet {
            oldValue?.cancel()
        }
    }

    private var defaultAvatarBackgroundColor: Color {
        guard let handle = currentUserSource.currentUser?.handle else { return .clear }
        return defaultBackgroundColor(handle: handle) ?? .clear
    }

    private var shouldShowPlan: Bool {
        !isBusinessAccount && !isProFlexiAccount
    }

    private var isBusinessAccount: Bool {
        accountUseCase.currentAccountDetails?.proLevel == .business
    }

    private var isProFlexiAccount: Bool {
        accountUseCase.currentAccountDetails?.proLevel == .proFlexi
    }

    private var accountDetailsMenuRowIndex: Int? {
        sections[.account]?.firstIndex { $0.title == fullNameHandler(currentUserSource) }
    }

    private var currentPlanMenuRowTitle: String {
        Strings.Localizable.InAppPurchase.ProductDetail.Navigation.currentPlan
    }

    private var currentPlanMenuRowIndex: Int? {
        sections[.account]?.firstIndex { $0.title == currentPlanMenuRowTitle }
    }

    private var storageUsedMenuRowTitle: String {
        Strings.Localizable.storage
    }

    private var storageUsedMenuRowIndex: Int? {
        sections[.account]?.firstIndex { $0.title == storageUsedMenuRowTitle }
    }

    private var rubbishBinMenuRowTitle: String {
        Strings.Localizable.rubbishBinLabel
    }

    private var rubbishBinMenuRowIndex: Int? {
        sections[.tools]?.firstIndex { $0.title == rubbishBinMenuRowTitle }
    }

    private var contactsMenuRowTitle: String {
        Strings.Localizable.contactsTitle
    }

    private var contactsMenuRowIndex: Int? {
        sections[.account]?.firstIndex { $0.title == contactsMenuRowTitle }
    }

    private var sharedItemsMenuRowTitle: String {
        Strings.Localizable.sharedItems
    }

    private var sharedItemsMenuRowIndex: Int? {
        sections[.tools]?.firstIndex { $0.title == sharedItemsMenuRowTitle }
    }

    private var sectionData: [AccountMenuSectionType: [AccountMenuOption]] {
        [
            .account: [
                accountDetailsMenuOption(
                    fullName: fullNameHandler(currentUserSource),
                    icon: Image(systemName: "circle.fill"),
                    iconStyle: .rounded,
                    backgroundColor: defaultAvatarBackgroundColor
                ),
                currentPlanMenuOption(accountDetails: accountUseCase.currentAccountDetails),
                storageUsedMenuOption(accountDetails: accountUseCase.currentAccountDetails),
                contactsMenuOption(),
                .init(
                    iconConfiguration: .init(icon: MEGAAssets.Image.achievementsInMenu),
                    title: Strings.Localizable.achievementsTitle,
                    rowType: .disclosure { [weak self] in self?.router.showAchievements() }
                )
            ],
            .tools: [
                sharedItemsMenuOption(),
                .init(
                    iconConfiguration: .init(icon: MEGAAssets.Image.deviceCentreInMenu),
                    title: Strings.Localizable.Device.Center.title,
                    rowType: .disclosure { [weak self] in self?.router.showDeviceCentre() }
                ),
                .init(
                    iconConfiguration: .init(icon: MEGAAssets.Image.transfersInMenu),
                    title: Strings.Localizable.transfers,
                    rowType: .disclosure { [weak self] in self?.router.showTransfers() }
                ),
                .init(
                    iconConfiguration: .init(icon: MEGAAssets.Image.offlineFilesInMenu),
                    title: Strings.Localizable.AccountMenu.offlineFiles,
                    rowType: .disclosure { [weak self] in self?.router.showOfflineFiles() }
                ),
                rubbishBinMenuOption(accountUseCase: accountUseCase),
                .init(
                    iconConfiguration: .init(icon: MEGAAssets.Image.settingsInMenu),
                    title: Strings.Localizable.settingsTitle,
                    rowType: .disclosure { [weak self] in self?.router.showSettings() }
                )
            ],
            .privacySuite: [
                .init(
                    iconConfiguration: .init(icon: MEGAAssets.Image.vpnAppInMenu),
                    title: Strings.Localizable.AccountMenu.MegaVPN.buttonTitle,
                    subtitle: Strings.Localizable.AccountMenu.MegaVPN.buttonSubtitle,
                    rowType: .externalLink { [weak self] in self?.router.openLink(for: .vpn) }
                ),
                .init(
                    iconConfiguration: .init(icon: MEGAAssets.Image.passAppInMenu),
                    title: Strings.Localizable.AccountMenu.MegaPass.buttonTitle,
                    subtitle: Strings.Localizable.AccountMenu.MegaPass.buttonSubtitle,
                    rowType: .externalLink { [weak self] in self?.router.openLink(for: .passwordManager) }
                ),
                .init(
                    iconConfiguration: .init(icon: MEGAAssets.Image.transferItAppInMenu),
                    title: Strings.Localizable.AccountMenu.TransferIt.buttonTitle,
                    subtitle: Strings.Localizable.AccountMenu.TransferIt.buttonSubtitle,
                    rowType: .externalLink { [weak self] in self?.router.openLink(for: .transferIt) }
                )
            ]
        ].mapValues { options in
            options.compactMap { $0 }
        }
    }

    public init(
        router: some AccountMenuViewRouting,
        currentUserSource: CurrentUserSource,
        tracker: some AnalyticsTracking,
        accountUseCase: some AccountUseCaseProtocol,
        userImageUseCase: some UserImageUseCaseProtocol,
        megaHandleUseCase: some MEGAHandleUseCaseProtocol,
        networkMonitorUseCase: some NetworkMonitorUseCaseProtocol,
        preferenceUseCase: some PreferenceUseCaseProtocol,
        notificationsUseCase: some NotificationsUseCaseProtocol,
        fullNameHandler: @escaping (CurrentUserSource) -> String,
        avatarFetchHandler: @escaping (String, HandleEntity) async -> UIImage?,
        logoutHandler: @escaping () async -> Void,
        sharedItemsNotificationCountHandler: @escaping () -> Int
    ) {
        self.router = router
        self.tracker = tracker
        self.accountUseCase = accountUseCase
        self.currentUserSource = currentUserSource
        self.userImageUseCase = userImageUseCase
        self.megaHandleUseCase = megaHandleUseCase
        self.networkMonitorUseCase = networkMonitorUseCase
        self.fullNameHandler = fullNameHandler
        self.avatarFetchHandler = avatarFetchHandler
        self.logoutHandler = logoutHandler
        self.sharedItemsNotificationCountHandler = sharedItemsNotificationCountHandler

        sections = sectionData
        $offlineLogOutWarningDismissed.useCase = preferenceUseCase
        Task { await refreshAccountData() }
        monitorAccountRefresh()
        updateAppNotificationCount(notificationsUseCase: notificationsUseCase)
        updateSharedItemsNotificationCount()
        updateContactsRequestNotificationCount()
    }

    deinit {
        monitorTask?.cancel()
        cancelTransfersTask?.cancel()
    }

    func refreshAccountData() async {
        async let avatarTask: () = fetchAvatarAndUpdateUI()
        async let detailsTask: () = fetchUpdatedAccountDetailsAndUpdateUI()
        _ = await (avatarTask, detailsTask)
    }

    func notificationButtonTapped() {
        tracker.trackAnalyticsEvent(with: NotificationsEntryButtonPressedEvent())
        router.showNotifications()
    }

    func logoutButtonTapped() {
        tracker.trackAnalyticsEvent(with: LogoutButtonPressedEvent())
        guard networkMonitorUseCase.isConnected() else { return }

        cancelTransfersTask = Task {
            await logoutHandler()
            offlineLogOutWarningDismissed = false
        }
    }

    private func showAccount() {
        tracker.trackAnalyticsEvent(with: MyAccountProfileNavigationItemEvent())
        router.showAccount()
    }

    private func upgradeAccount() {
        tracker.trackAnalyticsEvent(with: UpgradeMyAccountEvent())
        router.upgradeAccount()
    }

    private func fetchAvatarAndUpdateUI() async {
        guard let currentUser = currentUserSource.currentUser, let row = accountDetailsMenuRowIndex else {
            MEGALogError("Current user not found in currentUserSource")
            return
        }

        let fullName = fullNameHandler(currentUserSource)

        guard let avatar = await avatarImage(
            handle: currentUser.handle,
            fullName: fullName,
            userImageUseCase: userImageUseCase,
            megaHandleUseCase: megaHandleUseCase
        ) else { return }

        var updatedSections = sections
        updatedSections[.account]?[row] = accountDetailsMenuOption(
            fullName: fullName,
            icon: avatar,
            iconStyle: .rounded,
            backgroundColor: defaultAvatarBackgroundColor
        )
        sections = updatedSections
    }

    private func accountDetailsMenuOption(
        fullName: String,
        icon: Image,
        iconStyle: AccountMenuOption.IconConfiguration.IconStyle,
        backgroundColor: Color
    ) -> AccountMenuOption {
        .init(
            iconConfiguration: .init(icon: icon, style: iconStyle, backgroundColor: backgroundColor),
            title: fullName,
            subtitle: accountUseCase.myEmail ?? "",
            rowType: .disclosure { [weak self] in self?.showAccount() }
        )
    }

    private func fetchUpdatedAccountDetailsAndUpdateUI() async {
        do {
            let accountDetails = try await accountUseCase.refreshCurrentAccountDetails()
            var updatedSections = sections

            if let currentPlanMenuRowIndex, let menuOption = currentPlanMenuOption(accountDetails: accountDetails) {
                updatedSections[.account]?[currentPlanMenuRowIndex] = menuOption
            } else if shouldShowPlan {
                assertionFailure("Current plan menu row index not found")
            }

            if let storageUsedMenuRowIndex {
                updatedSections[.account]?[storageUsedMenuRowIndex] = storageUsedMenuOption(accountDetails: accountDetails)
            } else {
                assertionFailure("Storage used menu row index not found")
            }

            if let rubbishBinMenuRowIndex {
                updatedSections[.tools]?[rubbishBinMenuRowIndex] = rubbishBinMenuOption(
                    accountUseCase: accountUseCase
                )
            } else {
                assertionFailure("rubbish bin menu row index not found")
            }

            if let currentPlanMenuRowIndex {
                if let currentPlanMenuOption = currentPlanMenuOption(accountDetails: accountDetails) {
                    updatedSections[.account]?[currentPlanMenuRowIndex] = currentPlanMenuOption
                } else {
                    updatedSections[.account]?.remove(at: currentPlanMenuRowIndex)
                }
            }

            sections = updatedSections
        } catch {
            MEGALogDebug("Error while fetching account details: \(error)")
        }
    }

    private func avatarImage(
        handle: HandleEntity,
        fullName: String,
        userImageUseCase: some UserImageUseCaseProtocol,
        megaHandleUseCase: some MEGAHandleUseCaseProtocol
    ) async -> Image? {
        let image = await avatarFetchHandler(fullName, handle)
        guard let image else {
            MEGALogError("image not found for name \(fullName) handle \(handle)")
            return nil
        }
        return Image(uiImage: image)
    }

    private func defaultBackgroundColor(
        handle: HandleEntity
    ) -> Color? {
        guard let base64Handle = megaHandleUseCase.base64Handle(forUserHandle: handle) else {
            MEGALogError("base64 handle not found for handle \(handle)")
            return nil
        }

        guard let backgroundColor = userImageUseCase.avatarColorHex(forBase64UserHandle: base64Handle) else {
            MEGALogError("background color is nil for \(base64Handle)")
            return nil
        }

        return Color(hex: backgroundColor)
    }

    private func currentPlanMenuOption(accountDetails: AccountDetailsEntity?) -> AccountMenuOption? {
        guard shouldShowPlan else { return nil }
        let icon = if let accountDetails { currentPlanIcon(accountDetails: accountDetails) } else { MEGAAssets.Image.otherPlansInMenu }
        let rowType  = AccountMenuOption
            .AccountMenuRowType
            .withButton(title: Strings.Localizable.upgrade) { [weak self] in
                self?.upgradeAccount()
            }

        return .init(
            iconConfiguration: .init(icon: icon),
            title: currentPlanMenuRowTitle,
            subtitle: accountDetails?.proLevel.toAccountTypeDisplayName() ?? "",
            rowType: rowType
        )
    }

    private func currentPlanIcon(accountDetails: AccountDetailsEntity) -> Image {
        switch accountDetails.proLevel {
        case .lite: MEGAAssets.Image.proLitePlanInMenu
        case .proI: MEGAAssets.Image.proOnePlanInMenu
        case .proII: MEGAAssets.Image.proTwoPlanInMenu
        case .proIII: MEGAAssets.Image.proThreePlanInMenu
        default: MEGAAssets.Image.otherPlansInMenu
        }
    }

    private func storageUsedMenuOption(accountDetails: AccountDetailsEntity?) -> AccountMenuOption {
        let storageUsed = String.memoryStyleString(fromByteCount: accountDetails?.storageUsed ?? 0).formattedByteCountString()
        let totalStorage = String.memoryStyleString(fromByteCount: accountDetails?.storageMax ?? 0).formattedByteCountString()
        let subtitle = "\(storageUsed) / \(totalStorage)"

        return .init(
            iconConfiguration: .init(icon: MEGAAssets.Image.storageInMenu),
            title: storageUsedMenuRowTitle,
            subtitle: subtitle,
            rowType: .disclosure { [weak self] in self?.router.showStorage() }
        )
    }

    private func contactsMenuOption(contactRequestsCount: Int? = nil) -> AccountMenuOption {
        .init(
            iconConfiguration: .init(icon: MEGAAssets.Image.contactsInMenu),
            title: contactsMenuRowTitle,
            notificationCount: contactRequestsCount,
            rowType: .disclosure { [weak self] in self?.router.showContacts() }
        )
    }

    private func sharedItemsMenuOption(notificationsCount: Int? = nil) -> AccountMenuOption {
        .init(
            iconConfiguration: .init(icon: MEGAAssets.Image.sharedItemsInMenu),
            title: sharedItemsMenuRowTitle,
            notificationCount: notificationsCount,
            rowType: .disclosure { [weak self] in self?.router.showSharedItems() }
        )
    }

    private func rubbishBinMenuOption(accountUseCase: some AccountUseCaseProtocol) -> AccountMenuOption {
        let rubbishBinStorageUsed = accountUseCase.rubbishBinStorageUsed()
        let rubbishBinUsage = String
            .memoryStyleString(fromByteCount: rubbishBinStorageUsed)
            .formattedByteCountString()
        return .init(
            iconConfiguration: .init(icon: MEGAAssets.Image.rubbishBinInMenu),
            title: rubbishBinMenuRowTitle,
            subtitle: rubbishBinUsage,
            rowType: .disclosure { [weak self] in self?.router.showRubbishBin() }
        )
    }

    private func monitorAccountRefresh() {
        /// Monitors the account refresh process, primarily used after a plan purchase.
        monitorTask = Task { [weak self, accountUseCase] in
            for await _ in accountUseCase.monitorRefreshAccount.values {
                await self?.refreshAccountData()
            }
        }
    }

    private func updateAppNotificationCount(notificationsUseCase: some NotificationsUseCaseProtocol) {
        Task { @MainActor in
            let unreadNotificationsIdsCount = await notificationsUseCase.unreadNotificationIDs().count
            appNotificationsCount = Int(accountUseCase.relevantUnseenUserAlertsCount()) + unreadNotificationsIdsCount
        }
    }

    private func updateSharedItemsNotificationCount() {
        guard let sharedItemsMenuRowIndex else {
            assertionFailure("Shared items row not found in menu")
            return
        }

        let notificationsCount = sharedItemsNotificationCountHandler()
        sections[.tools]?[sharedItemsMenuRowIndex] = sharedItemsMenuOption(
            notificationsCount: notificationsCount > 0 ? notificationsCount : nil
        )
    }

    private func updateContactsRequestNotificationCount() {
        guard let contactsMenuRowIndex else {
            assertionFailure("Contacts row not found in menu")
            return
        }

        let contactRequestsCount = accountUseCase.incomingContactsRequestsCount()
        sections[.account]?[contactsMenuRowIndex] = contactsMenuOption(
            contactRequestsCount: contactRequestsCount > 0 ? contactRequestsCount : nil
        )
    }
}
