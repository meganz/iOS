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

        // Section Indexes for [.account]
        enum AccountSectionIndex: Int, CaseIterable {
            case accountDetails = 0
            case currentPlan
            case storageUsed
            case contacts
            case achievements

            static var totalCount: Int { allCases.count }
        }

        // Section Index for [.tools]
        enum ToolsSectionIndex: Int, CaseIterable {
            case sharedItems = 0
            case deviceCentre
            case transfers
            case offlineFiles
            case rubbishBin
            case settings

            static var totalCount: Int { allCases.count }
        }

        // Section Index for [.privacySuite]
        enum PrivacySuiteSectionIndex: Int, CaseIterable {
            case vpnApp = 0
            case pwmApp
            case transferItApp

            static var totalCount: Int { allCases.count }
        }
    }

    @Published var isPrivacySuiteExpanded = false
    @Published private(set) var sections: [AccountMenuSectionType: [AccountMenuOption?]] = [:]
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
    private var onAccountRequestFinishUpdatesTask: Task<Void, any Error>?
    private var onContactRequestsUpdatesTask: Task<Void, any Error>?
    private var onUserAlertsUpdatesTask: Task<Void, any Error>?
    private let notificationsUseCase: any NotificationsUseCaseProtocol

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

    private var sectionData: [AccountMenuSectionType: [AccountMenuOption?]] {
        [
            .account: accountSectionData,
            .tools: toolsSectionData,
            .privacySuite: privacySuiteSectionData
        ]
    }

    // Account section
    private var accountSectionData: [AccountMenuOption?] {
        var accountSection: [AccountMenuOption?] = .init(repeating: nil, count: Constants.AccountSectionIndex.totalCount)
        accountSection[Constants.AccountSectionIndex.accountDetails.rawValue] = accountDetailsMenuOption(
            iconConfiguration: .init(
                icon: Image(systemName: "circle.fill"),
                style: .rounded,
                backgroundColor: defaultAvatarBackgroundColor
            )
        )
        accountSection[Constants.AccountSectionIndex.currentPlan.rawValue] = currentPlanMenuOption(
            accountDetails: accountUseCase.currentAccountDetails
        )
        accountSection[Constants.AccountSectionIndex.storageUsed.rawValue] = storageUsedMenuOption(
            accountDetails: accountUseCase.currentAccountDetails
        )
        accountSection[Constants.AccountSectionIndex.contacts.rawValue] = contactsMenuOption()
        accountSection[Constants.AccountSectionIndex.achievements.rawValue] = AccountMenuOption(
            iconConfiguration: .init(icon: MEGAAssets.Image.achievementsInMenu),
            title: Strings.Localizable.achievementsTitle,
            rowType: .disclosure { [weak self] in self?.router.showAchievements() }
        )
        return accountSection
    }

    // Tools section
    private var toolsSectionData: [AccountMenuOption?] {
        var toolsSection: [AccountMenuOption?] = .init(repeating: nil, count: Constants.ToolsSectionIndex.totalCount)
        toolsSection[Constants.ToolsSectionIndex.sharedItems.rawValue] = sharedItemsMenuOption()
        toolsSection[Constants.ToolsSectionIndex.deviceCentre.rawValue] = AccountMenuOption(
            iconConfiguration: .init(icon: MEGAAssets.Image.deviceCentreInMenu),
            title: Strings.Localizable.Device.Center.title,
            rowType: .disclosure { [weak self] in self?.router.showDeviceCentre() }
        )
        toolsSection[Constants.ToolsSectionIndex.transfers.rawValue] = AccountMenuOption(
            iconConfiguration: .init(icon: MEGAAssets.Image.transfersInMenu),
            title: Strings.Localizable.transfers,
            rowType: .disclosure { [weak self] in self?.router.showTransfers() }
        )
        toolsSection[Constants.ToolsSectionIndex.offlineFiles.rawValue] = AccountMenuOption(
            iconConfiguration: .init(icon: MEGAAssets.Image.offlineFilesInMenu),
            title: Strings.Localizable.AccountMenu.offlineFiles,
            rowType: .disclosure { [weak self] in self?.router.showOfflineFiles() }
        )
        toolsSection[Constants.ToolsSectionIndex.rubbishBin.rawValue] = rubbishBinMenuOption(
            accountUseCase: accountUseCase
        )
        toolsSection[Constants.ToolsSectionIndex.settings.rawValue] = AccountMenuOption(
            iconConfiguration: .init(icon: MEGAAssets.Image.settingsInMenu),
            title: Strings.Localizable.settingsTitle,
            rowType: .disclosure { [weak self] in self?.router.showSettings() }
        )
        return toolsSection
    }

    // Privacy suite section
    private var privacySuiteSectionData: [AccountMenuOption?] {
        var privacySuiteSection: [AccountMenuOption?] = .init(
            repeating: nil,
            count: Constants.PrivacySuiteSectionIndex.totalCount
        )
        privacySuiteSection[Constants.PrivacySuiteSectionIndex.vpnApp.rawValue] = AccountMenuOption(
            iconConfiguration: .init(icon: MEGAAssets.Image.vpnAppInMenu),
            title: Strings.Localizable.AccountMenu.MegaVPN.buttonTitle,
            subtitle: Strings.Localizable.AccountMenu.MegaVPN.buttonSubtitle,
            rowType: .externalLink { [weak self] in self?.router.openLink(for: .vpn) }
        )
        privacySuiteSection[Constants.PrivacySuiteSectionIndex.pwmApp.rawValue] = AccountMenuOption(
            iconConfiguration: .init(icon: MEGAAssets.Image.passAppInMenu),
            title: Strings.Localizable.AccountMenu.MegaPass.buttonTitle,
            subtitle: Strings.Localizable.AccountMenu.MegaPass.buttonSubtitle,
            rowType: .externalLink { [weak self] in self?.router.openLink(for: .passwordManager) }
        )
        privacySuiteSection[Constants.PrivacySuiteSectionIndex.transferItApp.rawValue] = AccountMenuOption(
            iconConfiguration: .init(icon: MEGAAssets.Image.transferItAppInMenu),
            title: Strings.Localizable.AccountMenu.TransferIt.buttonTitle,
            subtitle: Strings.Localizable.AccountMenu.TransferIt.buttonSubtitle,
            rowType: .externalLink { [weak self] in self?.router.openLink(for: .transferIt) }
        )
        return privacySuiteSection
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
        self.notificationsUseCase = notificationsUseCase

        sections = sectionData
        $offlineLogOutWarningDismissed.useCase = preferenceUseCase
        Task { await updateUI() }
        monitorAccountRefresh()
        updateSharedItemsNotificationCount()
        updateContactsRequestNotificationCount()
        listenToAccountRequestFinishUpdates()
        listenToContactsRequestsUpdates()
        listenToUserAlertsUpdates()
    }

    deinit {
        monitorTask?.cancel()
        cancelTransfersTask?.cancel()
        onAccountRequestFinishUpdatesTask?.cancel()
        onContactRequestsUpdatesTask?.cancel()
    }

    func updateUI() async {
        async let updateAppNotificationTask: () = updateAppNotificationCount()
        async let refreshAccountDataTask: () = refreshAccountData()
        _ = await (updateAppNotificationTask, refreshAccountDataTask)
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

    private func refreshAccountData() async {
        async let avatarTask: () = fetchAvatarAndUpdateUI()
        async let detailsTask: () = fetchUpdatedAccountDetailsAndUpdateUI()
        _ = await (avatarTask, detailsTask)
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
        guard let currentUser = currentUserSource.currentUser else {
            MEGALogError("Current user not found in currentUserSource")
            return
        }

        guard let avatar = await avatarImage(
            handle: currentUser.handle,
            userImageUseCase: userImageUseCase,
            megaHandleUseCase: megaHandleUseCase
        ) else { return }

        var updatedSections = sections
        updatedSections[.account]?[Constants.AccountSectionIndex.accountDetails.rawValue] = accountDetailsMenuOption(
            iconConfiguration: .init(
                icon: avatar,
                style: .rounded,
                backgroundColor: defaultAvatarBackgroundColor
            )
        )

        sections = updatedSections
    }

    private func accountDetailsMenuOption(iconConfiguration: AccountMenuOption.IconConfiguration) -> AccountMenuOption {
        .init(
            iconConfiguration: iconConfiguration,
            title: fullNameHandler(currentUserSource),
            subtitle: accountUseCase.myEmail ?? "",
            rowType: .disclosure { [weak self] in self?.showAccount() }
        )
    }

    private func fetchUpdatedAccountDetailsAndUpdateUI() async {
        do {
            let accountDetails = try await accountUseCase.refreshCurrentAccountDetails()
            updateUI(with: accountDetails)
        } catch {
            MEGALogDebug("Error while fetching account details: \(error)")
        }
    }

    private func updateUI(with accountDetails: AccountDetailsEntity) {
        var updatedSections = sections

        if let iconConfiguration = updatedSections[.account]?[Constants.AccountSectionIndex.accountDetails.rawValue]?.iconConfiguration {
            updatedSections[.account]?[Constants.AccountSectionIndex.accountDetails.rawValue] = accountDetailsMenuOption(
                iconConfiguration: iconConfiguration
            )
        }

        updatedSections[.account]?[Constants.AccountSectionIndex.currentPlan.rawValue] = currentPlanMenuOption(
            accountDetails: accountDetails
        )

        updatedSections[.account]?[Constants.AccountSectionIndex.storageUsed.rawValue] = storageUsedMenuOption(
            accountDetails: accountDetails
        )

        updatedSections[.tools]?[Constants.ToolsSectionIndex.rubbishBin.rawValue] = rubbishBinMenuOption(
            accountUseCase: accountUseCase
        )

        sections = updatedSections
    }

    private func avatarImage(
        handle: HandleEntity,
        userImageUseCase: some UserImageUseCaseProtocol,
        megaHandleUseCase: some MEGAHandleUseCaseProtocol
    ) async -> Image? {
        let fullName = fullNameHandler(currentUserSource)
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
            title: Strings.Localizable.InAppPurchase.ProductDetail.Navigation.currentPlan,
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
            title: Strings.Localizable.storage,
            subtitle: subtitle,
            rowType: .disclosure { [weak self] in self?.router.showStorage() }
        )
    }

    private func contactsMenuOption(contactRequestsCount: Int? = nil) -> AccountMenuOption {
        .init(
            iconConfiguration: .init(icon: MEGAAssets.Image.contactsInMenu),
            title: Strings.Localizable.contactsTitle,
            notificationCount: contactRequestsCount,
            rowType: .disclosure { [weak self] in self?.router.showContacts() }
        )
    }

    private func sharedItemsMenuOption(notificationsCount: Int? = nil) -> AccountMenuOption {
        .init(
            iconConfiguration: .init(icon: MEGAAssets.Image.sharedItemsInMenu),
            title: Strings.Localizable.sharedItems,
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
            title: Strings.Localizable.rubbishBinLabel,
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

    private func updateAppNotificationCount() async {
        let unreadNotificationsIdsCount = await notificationsUseCase.unreadNotificationIDs().count
        appNotificationsCount = Int(accountUseCase.relevantUnseenUserAlertsCount()) + unreadNotificationsIdsCount
    }

    private func updateSharedItemsNotificationCount() {
        let notificationsCount = sharedItemsNotificationCountHandler()
        sections[.tools]?[Constants.ToolsSectionIndex.sharedItems.rawValue] = sharedItemsMenuOption(
            notificationsCount: notificationsCount > 0 ? notificationsCount : nil
        )
    }

    private func updateContactsRequestNotificationCount() {
        let contactRequestsCount = accountUseCase.incomingContactsRequestsCount()
        sections[.account]?[Constants.AccountSectionIndex.contacts.rawValue] = contactsMenuOption(
            contactRequestsCount: contactRequestsCount > 0 ? contactRequestsCount : nil
        )
    }

    private func listenToContactsRequestsUpdates() {
        onContactRequestsUpdatesTask = Task { [weak self, accountUseCase] in
            for await _ in accountUseCase.onContactRequestsUpdates {
                guard let self else { return }
                try Task.checkCancellation()
                updateContactsRequestNotificationCount()
            }
        }
    }

    private func listenToAccountRequestFinishUpdates() {
        onAccountRequestFinishUpdatesTask = Task { [weak self, accountUseCase] in
            for await resultRequest in accountUseCase.onAccountRequestFinish {
                guard let self else { return }
                try Task.checkCancellation()

                await handleRequestResult(resultRequest)
            }
        }
    }

    private func handleRequestResult(_ result: Result<AccountRequestEntity, any Error>) async {
        if case .success(let request) = result {
            switch request.type {
            case .accountDetails:
                if let currentAccountDetails = accountUseCase.currentAccountDetails {
                    updateUI(with: currentAccountDetails)
                }
            case .getAttrUser:
                if request.file != nil {
                    await fetchAvatarAndUpdateUI()
                }

                if (request.userAttribute == .firstName || request.userAttribute == .lastName) &&
                    request.email == nil {
                    await fetchUpdatedAccountDetailsAndUpdateUI()
                }
            default:
                MEGALogDebug("[Menu] Received \(request.type) request type but will not handle here")
                return
            }
        }
    }

    private func listenToUserAlertsUpdates() {
        onUserAlertsUpdatesTask = Task { [weak self, accountUseCase] in
            for await _ in accountUseCase.onUserAlertsUpdates {
                guard let self else { return }
                try Task.checkCancellation()
                await updateAppNotificationCount()
            }
        }
    }
}
