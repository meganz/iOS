import Combine
import MEGAAppSDKRepo
import MEGAAssets
import MEGADesignToken
import MEGADomain
import MEGAL10n
import MEGASwift
import MEGAUIKit
import SwiftUI

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
        static let accountDetailsIndex = 0
        static let currentPlanIndex = 1
        static let storageUsedIndex = 2

        // Section Index for [.tools]
        static let rubbishBinIndex = 4
    }

    @Published var isPrivacySuiteExpanded = false
    @Published private(set) var sections: [AccountMenuSectionType: [AccountMenuOption]] = [:]

    @Published var isAtTop = true

    private let accountUseCase: any AccountUseCaseProtocol
    private let currentUserSource: CurrentUserSource
    private let userImageUseCase: any UserImageUseCaseProtocol
    private let megaHandleUseCase: any MEGAHandleUseCaseProtocol
    private var monitorTask: Task<Void, Never>?
    private let fullNameHandler: (CurrentUserSource) -> String
    private let avatarFetchHandler: (String, HandleEntity) async -> UIImage?

    private var defaultAvatarBackgroundColor: Color {
        guard let handle = currentUserSource.currentUser?.handle else { return .clear }
        return defaultBackgroundColor(handle: handle) ?? .clear
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
                .init(
                    iconConfiguration: .init(icon: MEGAAssets.Image.contactsInMenu),
                    title: Strings.Localizable.contactsTitle,
                    subtitle: nil,
                    rowType: .disclosure
                ),
                .init(
                    iconConfiguration: .init(icon: MEGAAssets.Image.achievementsInMenu),
                    title: Strings.Localizable.achievementsTitle,
                    subtitle: nil,
                    rowType: .disclosure
                )
            ],
            .tools: [
                .init(
                    iconConfiguration: .init(icon: MEGAAssets.Image.sharedItemsInMenu),
                    title: Strings.Localizable.sharedItems,
                    subtitle: nil,
                    rowType: .disclosure
                ),
                .init(
                    iconConfiguration: .init(icon: MEGAAssets.Image.deviceCentreInMenu),
                    title: Strings.Localizable.Device.Center.title,
                    subtitle: nil,
                    rowType: .disclosure
                ),
                .init(
                    iconConfiguration: .init(icon: MEGAAssets.Image.transfersInMenu),
                    title: Strings.Localizable.transfers,
                    subtitle: nil,
                    rowType: .disclosure
                ),
                .init(
                    iconConfiguration: .init(icon: MEGAAssets.Image.offlineFilesInMenu),
                    title: Strings.Localizable.AccountMenu.offlineFiles,
                    subtitle: nil,
                    rowType: .disclosure
                ),
                rubbishBinMenuOption(accountUseCase: accountUseCase),
                .init(
                    iconConfiguration: .init(icon: MEGAAssets.Image.settingsInMenu),
                    title: Strings.Localizable.settingsTitle,
                    subtitle: nil,
                    rowType: .disclosure
                )
            ],
            .privacySuite: [
                .init(
                    iconConfiguration: .init(icon: MEGAAssets.Image.vpnAppInMenu),
                    title: Strings.Localizable.AccountMenu.MegaVPN.buttonTitle,
                    subtitle: Strings.Localizable.AccountMenu.MegaVPN.buttonSubtitle,
                    rowType: .externalLink
                ),
                .init(
                    iconConfiguration: .init(icon: MEGAAssets.Image.passAppInMenu),
                    title: Strings.Localizable.AccountMenu.MegaPass.buttonTitle,
                    subtitle: Strings.Localizable.AccountMenu.MegaPass.buttonSubtitle,
                    rowType: .externalLink
                ),
                .init(
                    iconConfiguration: .init(icon: MEGAAssets.Image.transferItAppInMenu),
                    title: Strings.Localizable.AccountMenu.TransferIt.buttonTitle,
                    subtitle: Strings.Localizable.AccountMenu.TransferIt.buttonSubtitle,
                    rowType: .externalLink
                )
            ]
        ]
    }

    public init(
        currentUserSource: CurrentUserSource,
        accountUseCase: some AccountUseCaseProtocol,
        userImageUseCase: some UserImageUseCaseProtocol,
        megaHandleUseCase: some MEGAHandleUseCaseProtocol,
        fullNameHandler: @escaping (CurrentUserSource) -> String,
        avatarFetchHandler: @escaping (String, HandleEntity) async -> UIImage?
    ) {
        self.accountUseCase = accountUseCase
        self.currentUserSource = currentUserSource
        self.userImageUseCase = userImageUseCase
        self.megaHandleUseCase = megaHandleUseCase
        self.fullNameHandler = fullNameHandler
        self.avatarFetchHandler = avatarFetchHandler

        sections = sectionData
        Task { await refreshAccountData() }
        monitorAccountRefresh()
    }

    deinit {
        monitorTask?.cancel()
    }

    func refreshAccountData() async {
        async let avatarTask: () = fetchAvatarAndUpdateUI()
        async let detailsTask: () = fetchUpdatedAccountDetailsAndUpdateUI()
        _ = await (avatarTask, detailsTask)
    }

    private func fetchAvatarAndUpdateUI() async {
        guard let currentUser = currentUserSource.currentUser else {
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
        updatedSections[.account]?[Constants.accountDetailsIndex] = accountDetailsMenuOption(
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
            rowType: .disclosure
        )
    }

    private func fetchUpdatedAccountDetailsAndUpdateUI() async {
        do {
            let accountDetails = try await accountUseCase.refreshCurrentAccountDetails()
            var updatedSections = sections
            updatedSections[.account]?[Constants.currentPlanIndex] = currentPlanMenuOption(accountDetails: accountDetails)
            updatedSections[.account]?[Constants.storageUsedIndex] = storageUsedMenuOption(accountDetails: accountDetails)
            updatedSections[.tools]?[Constants.rubbishBinIndex] = rubbishBinMenuOption(accountUseCase: accountUseCase)
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

    private func currentPlanMenuOption(accountDetails: AccountDetailsEntity?) -> AccountMenuOption {
        let icon = if let accountDetails { currentPlanIcon(accountDetails: accountDetails) } else { MEGAAssets.Image.otherPlansInMenu }

        return .init(
            iconConfiguration: .init(icon: icon),
            title: Strings.Localizable.InAppPurchase.ProductDetail.Navigation.currentPlan,
            subtitle: accountDetails?.proLevel.toAccountTypeDisplayName() ?? "",
            rowType: .withButton(title: Strings.Localizable.upgrade, action: { })
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
            rowType: .disclosure
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
            rowType: .disclosure
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
}
