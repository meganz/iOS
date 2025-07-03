@testable import Accounts
import MEGAAppPresentation
import MEGAAppPresentationMock
import MEGAAppSDKRepo
import MEGAAppSDKRepoMock
import MEGADomain
import MEGADomainMock
import MEGAL10n
import MEGAPreference
import MEGASwift
import Testing
import UIKit

@MainActor
struct AccountMenuViewModelTess {

    @Test("Test init method")
    func testInit() {
        let sut = makeSUT()
        #expect(sut.isAtTop == true)
        #expect(Set(sut.sections.keys) == Set([.account, .tools, .privacySuite]))
        #expect(sut.isPrivacySuiteExpanded == false)
    }

    @Test("Test for account row data")
    func testAccountRowData() {
        let accountUseCase = MockAccountUseCase(email: "email@test.com")
        let sut = makeSUT(accountUseCase: accountUseCase)
        let accountSection = sut.sections[.account]
        let accountRowData = accountSection?.first
        #expect(accountRowData?.title == "")
        #expect(accountRowData?.subtitle == "email@test.com")
        #expect(accountRowData?.rowType == .disclosure(action: {}))
        #expect(accountRowData?.iconConfiguration.style == .rounded)
    }

    @Test("Test for plan row data")
    func testPlanRowData() {
        let accountUseCase = MockAccountUseCase(currentAccountDetails: MockMEGAAccountDetails(type: .proI).toAccountDetailsEntity())
        let sut = makeSUT(accountUseCase: accountUseCase)
        let accountSection = sut.sections[.account]
        let planRowData = accountSection?[1]
        #expect(planRowData?.title == Strings.Localizable.InAppPurchase.ProductDetail.Navigation.currentPlan)
        #expect(
            planRowData?.subtitle == MockMEGAAccountDetails(type: .proI)
                .toAccountDetailsEntity()
                .proLevel
                .toAccountTypeDisplayName()
        )
        #expect(planRowData?.rowType == .withButton(title: Strings.Localizable.upgrade, action: { }))
        #expect(planRowData?.iconConfiguration.style == .normal)
    }

    @Test("Test for storage row data")
    func testStorageRowData() {
        let accountUseCase = MockAccountUseCase(
            currentAccountDetails: MockMEGAAccountDetails(storageUsed: 10, storageMax: 100, type: .proI)
                .toAccountDetailsEntity()
        )
        let sut = makeSUT(accountUseCase: accountUseCase)
        let accountSection = sut.sections[.account]
        let storageRowData = accountSection?[2]
        #expect(storageRowData?.title == Strings.Localizable.storage)
        #expect(storageRowData?.subtitle == "10 B / 100 B")
        #expect(storageRowData?.rowType == .disclosure(action: {}))
        #expect(storageRowData?.iconConfiguration.style == .normal)
    }

    @Test("Test contacts row data")
    func testContactsRowData() {
        let sut = makeSUT()
        let accountSection = sut.sections[.account]
        let contactsRowData = accountSection?[3]
        #expect(contactsRowData?.title == Strings.Localizable.contactsTitle)
        #expect(contactsRowData?.subtitle == nil)
        #expect(contactsRowData?.rowType == .disclosure(action: {}))
        #expect(contactsRowData?.iconConfiguration.style == .normal)
    }

    @Test("Test achievements row data")
    func testAchievementsRowData() {
        let sut = makeSUT()
        let accountSection = sut.sections[.account]
        let achievementsRowData = accountSection?[4]
        #expect(achievementsRowData?.title == Strings.Localizable.achievementsTitle)
        #expect(achievementsRowData?.subtitle == nil)
        #expect(achievementsRowData?.rowType == .disclosure(action: {}))
        #expect(achievementsRowData?.iconConfiguration.style == .normal)
    }

    @Test("Test shared items row data")
    func testSharedItemsRowData() {
        let sut = makeSUT()
        let toolsSection = sut.sections[.tools]
        let sharedItemsRowData = toolsSection?[0]
        #expect(sharedItemsRowData?.title == Strings.Localizable.sharedItems)
        #expect(sharedItemsRowData?.subtitle == nil)
        #expect(sharedItemsRowData?.rowType == .disclosure(action: {}))
        #expect(sharedItemsRowData?.iconConfiguration.style == .normal)
    }

    @Test("Test device center row data")
    func testDeviceCenterRowData() {
        let sut = makeSUT()
        let toolsSection = sut.sections[.tools]
        let deviceCenterRowData = toolsSection?[1]
        #expect(deviceCenterRowData?.title == Strings.Localizable.Device.Center.title)
        #expect(deviceCenterRowData?.subtitle == nil)
        #expect(deviceCenterRowData?.rowType == .disclosure(action: {}))
        #expect(deviceCenterRowData?.iconConfiguration.style == .normal)
    }

    @Test("Test transfers row data")
    func testTransfersRowData() {
        let sut = makeSUT()
        let toolsSection = sut.sections[.tools]
        let transfersRowData = toolsSection?[2]
        #expect(transfersRowData?.title == Strings.Localizable.transfers)
        #expect(transfersRowData?.subtitle == nil)
        #expect(transfersRowData?.rowType == .disclosure(action: {}))
        #expect(transfersRowData?.iconConfiguration.style == .normal)
    }

    @Test("Test offline files row data")
    func testOfflineFilesRowData() {
        let sut = makeSUT()
        let toolsSection = sut.sections[.tools]
        let offlineFilesRowData = toolsSection?[3]
        #expect(offlineFilesRowData?.title == Strings.Localizable.AccountMenu.offlineFiles)
        #expect(offlineFilesRowData?.subtitle == nil)
        #expect(offlineFilesRowData?.rowType == .disclosure(action: {}))
        #expect(offlineFilesRowData?.iconConfiguration.style == .normal)
    }

    @Test("Test rubbish bin row data")
    func testRubbishBinRowData() {
        let accountUseCase = MockAccountUseCase(rubbishBinStorage: 200)
        let sut = makeSUT(accountUseCase: accountUseCase)
        let toolsSection = sut.sections[.tools]
        let rubbishBinRowData = toolsSection?[4]
        #expect(rubbishBinRowData?.title == Strings.Localizable.rubbishBinLabel)
        #expect(rubbishBinRowData?.subtitle == "200 B")
        #expect(rubbishBinRowData?.rowType == .disclosure(action: {}))
        #expect(rubbishBinRowData?.iconConfiguration.style == .normal)
    }

    @Test("Test settings row data")
    func testSettingsRowData() {
        let sut = makeSUT()
        let toolsSection = sut.sections[.tools]
        let settingsRowData = toolsSection?[5]
        #expect(settingsRowData?.title == Strings.Localizable.settingsTitle)
        #expect(settingsRowData?.subtitle == nil)
        #expect(settingsRowData?.rowType == .disclosure(action: {}))
        #expect(settingsRowData?.iconConfiguration.style == .normal)
    }

    @Test("Test VPN app row data")
    func testVPNAPPRowData() {
        let sut = makeSUT()
        let privacySuiteSection = sut.sections[.privacySuite]
        let megaVPNAppRowData = privacySuiteSection?[0]
        #expect(megaVPNAppRowData?.title == Strings.Localizable.AccountMenu.MegaVPN.buttonTitle)
        #expect(megaVPNAppRowData?.subtitle == Strings.Localizable.AccountMenu.MegaVPN.buttonSubtitle)
        #expect(megaVPNAppRowData?.rowType == .externalLink(action: {}))
        #expect(megaVPNAppRowData?.iconConfiguration.style == .normal)
    }

    @Test("Test Pass app row data")
    func testPassAppRowData() {
        let sut = makeSUT()
        let privacySuiteSection = sut.sections[.privacySuite]
        let passRowData = privacySuiteSection?[1]
        #expect(passRowData?.title == Strings.Localizable.AccountMenu.MegaPass.buttonTitle)
        #expect(passRowData?.subtitle == Strings.Localizable.AccountMenu.MegaPass.buttonSubtitle)
        #expect(passRowData?.rowType == .externalLink(action: {}))
        #expect(passRowData?.iconConfiguration.style == .normal)
    }

    @Test("Test transfer it app row data")
    func testTransferAppRowData() {
        let sut = makeSUT()
        let privacySuiteSection = sut.sections[.privacySuite]
        let transferItAppRowData = privacySuiteSection?[2]
        #expect(transferItAppRowData?.title == Strings.Localizable.AccountMenu.TransferIt.buttonTitle)
        #expect(transferItAppRowData?.subtitle == Strings.Localizable.AccountMenu.TransferIt.buttonSubtitle)
        #expect(transferItAppRowData?.rowType == .externalLink(action: {}))
        #expect(transferItAppRowData?.iconConfiguration.style == .normal)
    }

    @Test("Test refresh account details")
    func testRefreshAccountDetails() async {
        let accountUseCase = MockAccountUseCase(
            currentAccountDetails: MockMEGAAccountDetails(storageUsed: 10, storageMax: 100, type: .proI)
                .toAccountDetailsEntity(),
            accountDetailsResult: .success(MockMEGAAccountDetails(storageUsed: 20, storageMax: 200, type: .proII)
                .toAccountDetailsEntity())
        )

        let sut = makeSUT(accountUseCase: accountUseCase)
        await sut.refreshAccountData()

        let accountSection = sut.sections[.account]
        let planRowData = accountSection?[1]
        #expect(
            planRowData?.subtitle == MockMEGAAccountDetails(type: .proII)
                .toAccountDetailsEntity()
                .proLevel
                .toAccountTypeDisplayName()
        )

        let storageRowData = accountSection?[2]
        #expect(storageRowData?.title == Strings.Localizable.storage)
        #expect(storageRowData?.subtitle == "20 B / 200 B")
    }

    @Test("Test account details tap")
    func testAccountDetailsTap() throws {
        let router = MockMenuViewRouter()
        let sut = makeSUT(router: router)
        let accountSection = try #require(sut.sections[.account], "Account section should exist")
        let accountInfoRow = try #require(accountSection.first, "Account section should have at least one row")

        guard case let .disclosure(action) = accountInfoRow.rowType else {
            Issue.record("Expected disclosure row type but got \(accountInfoRow.rowType)")
            return
        }

        #expect(router.showAccount_calledTimes == 0)
        action()
        #expect(router.showAccount_calledTimes == 1)
    }

    @Test("Test upgrade button tap")
    func testUpgradeButtonTap() throws {
        let router = MockMenuViewRouter()
        let sut = makeSUT(router: router)
        let accountSection = try #require(sut.sections[.account], "Account section should exist")
        let currentPlanRow = accountSection[1]

        guard case .withButton(_, let action) = currentPlanRow.rowType else {
            Issue.record("Expected button row type but got \(currentPlanRow.rowType)")
            return
        }

        #expect(router.upgradeAccount_calledTimes == 0)
        action()
        #expect(router.upgradeAccount_calledTimes == 1)
    }

    @Test("Test storage row tap")
    func testStorageRowTap() throws {
        let router = MockMenuViewRouter()
        let sut = makeSUT(router: router)
        let accountSection = try #require(sut.sections[.account], "Account section should exist")
        let storageRow = accountSection[2]

        guard case .disclosure(let action) = storageRow.rowType else {
            Issue.record("Expected button row type but got \(storageRow.rowType)")
            return
        }

        #expect(router.showStorage_calledTimes == 0)
        action()
        #expect(router.showStorage_calledTimes == 1)
    }

    @Test("Test contacts row tap")
    func testContactsRowTap() throws {
        let router = MockMenuViewRouter()
        let sut = makeSUT(router: router)
        let accountSection = try #require(sut.sections[.account], "Account section should exist")
        let contactsRow = accountSection[3]

        guard case .disclosure(let action) = contactsRow.rowType else {
            Issue.record("Expected disclosure row type but got \(contactsRow.rowType)")
            return
        }

        #expect(router.showContacts_calledTimes == 0)
        action()
        #expect(router.showContacts_calledTimes == 1)
    }

    @Test("Test achievements row tap")
    func testAchievementsRowTap() throws {
        let router = MockMenuViewRouter()
        let sut = makeSUT(router: router)
        let accountSection = try #require(sut.sections[.account], "Account section should exist")
        let achievementsRow = accountSection[4]

        guard case .disclosure(let action) = achievementsRow.rowType else {
            Issue.record("Expected disclosure row type but got \(achievementsRow.rowType)")
            return
        }

        #expect(router.showAchievements_calledTimes == 0)
        action()
        #expect(router.showAchievements_calledTimes == 1)
    }

    @Test("Test shared items row tap")
    func testSharedItemsRowTap() throws {
        let router = MockMenuViewRouter()
        let sut = makeSUT(router: router)
        let toolsSection = try #require(sut.sections[.tools], "Tools section should exist")
        let sharedItemsRow = try #require(toolsSection.first, "Tools section should contain at least one row")

        guard case .disclosure(let action) = sharedItemsRow.rowType else {
            Issue.record("Expected disclosure row type but got \(sharedItemsRow.rowType)")
            return
        }

        #expect(router.showSharedItems_calledTimes == 0)
        action()
        #expect(router.showSharedItems_calledTimes == 1)
    }

    @Test("Test device center row tap")
    func testDeviceCenterRowTap() throws {
        let router = MockMenuViewRouter()
        let sut = makeSUT(router: router)
        let toolsSection = try #require(sut.sections[.tools], "Tools section should exist")
        let deviceCenterRow = toolsSection[1]

        guard case .disclosure(let action) = deviceCenterRow.rowType else {
            Issue.record("Expected disclosure row type but got \(deviceCenterRow.rowType)")
            return
        }

        #expect(router.showDeviceCentre_calledTimes == 0)
        action()
        #expect(router.showDeviceCentre_calledTimes == 1)
    }

    @Test("Test transfers row tap")
    func testTransfersRowTap() throws {
        let router = MockMenuViewRouter()
        let sut = makeSUT(router: router)
        let toolsSection = try #require(sut.sections[.tools], "Tools section should exist")
        let transfersRow = toolsSection[2]

        guard case .disclosure(let action) = transfersRow.rowType else {
            Issue.record("Expected disclosure row type but got \(transfersRow.rowType)")
            return
        }

        #expect(router.showTransfers_calledTimes == 0)
        action()
        #expect(router.showTransfers_calledTimes == 1)
    }

    @Test("Test offline files row tap")
    func testOfflineFilesRowTap() throws {
        let router = MockMenuViewRouter()
        let sut = makeSUT(router: router)
        let toolsSection = try #require(sut.sections[.tools], "Tools section should exist")
        let offlineFilesRow = toolsSection[3]

        guard case .disclosure(let action) = offlineFilesRow.rowType else {
            Issue.record("Expected disclosure row type but got \(offlineFilesRow.rowType)")
            return
        }

        #expect(router.showOfflineFiles_calledTimes == 0)
        action()
        #expect(router.showOfflineFiles_calledTimes == 1)
    }

    @Test("Test rubbish bin row tap")
    func testRubbishBinRowTap() throws {
        let router = MockMenuViewRouter()
        let sut = makeSUT(router: router)
        let toolsSection = try #require(sut.sections[.tools], "Tools section should exist")
        let rubbishBinRow = toolsSection[4]

        guard case .disclosure(let action) = rubbishBinRow.rowType else {
            Issue.record("Expected disclosure row type but got \(rubbishBinRow.rowType)")
            return
        }

        #expect(router.showRubbishBin_calledTimes == 0)
        action()
        #expect(router.showRubbishBin_calledTimes == 1)
    }

    @Test("Test settings row tap")
    func testSettingsRowTap() throws {
        let router = MockMenuViewRouter()
        let sut = makeSUT(router: router)
        let toolsSection = try #require(sut.sections[.tools], "Tools section should exist")
        let settingsRow = try #require(toolsSection.last, "Tools section should contain at least one row")

        guard case .disclosure(let action) = settingsRow.rowType else {
            Issue.record("Expected disclosure row type but got \(settingsRow.rowType)")
            return
        }

        #expect(router.showSettings_calledTimes == 0)
        action()
        #expect(router.showSettings_calledTimes == 1)
    }

    @Test("Test VPN button tap")
    func testVPNButtonTap() throws {
        let router = MockMenuViewRouter()
        let sut = makeSUT(router: router)
        let privacySection = try #require(sut.sections[.privacySuite], "Privacy Suite section should exist")
        let vpnRow = try #require(privacySection.first, "Privacy section should contain at least one row")

        guard case .externalLink(let action) = vpnRow.rowType else {
            Issue.record("Expected external link row type but got \(vpnRow.rowType)")
            return
        }

        #expect(router.openLink_calledTimes == 0)
        action()
        #expect(router.openLink_calledTimes == 1)
        #expect(router.openLink_lastApp == .vpn)
    }

    @Test("Test MegaPass button tap")
    func testMegaPassButtonTap() throws {
        let router = MockMenuViewRouter()
        let sut = makeSUT(router: router)
        let privacySection = try #require(sut.sections[.privacySuite], "Privacy Suite section should exist")
        let passRow = privacySection[1]

        guard case .externalLink(let action) = passRow.rowType else {
            Issue.record("Expected external link row type but got \(passRow.rowType)")
            return
        }

        #expect(router.openLink_calledTimes == 0)
        action()
        #expect(router.openLink_calledTimes == 1)
        #expect(router.openLink_lastApp == .passwordManager)
    }

    @Test("Test TransferIt button tap")
    func testTransferItButtonTap() throws {
        let router = MockMenuViewRouter()
        let sut = makeSUT(router: router)
        let privacySection = try #require(sut.sections[.privacySuite], "Privacy Suite section should exist")
        let transferItRow = try #require(privacySection.last, "Privacy section should contain at least one row")

        guard case .externalLink(let action) = transferItRow.rowType else {
            Issue.record("Expected external link row type but got \(transferItRow.rowType)")
            return
        }

        #expect(router.openLink_calledTimes == 0)
        action()
        #expect(router.openLink_calledTimes == 1)
        #expect(router.openLink_lastApp == .transferIt)
    }

    @Test(arguments: [
        true,
        false
    ])
    func testLogoutButtonTap(connected: Bool) async throws {
        let networkUseCase = MockNetworkMonitorUseCase(connected: connected)
        @Atomic var didCallLogoutHandler = false
        let preferenceUseCase = MockPreferenceUseCase()
        let sut = makeSUT(preferenceUseCase: preferenceUseCase, networkMonitorUseCase: networkUseCase, logoutHandler: {
            $didCallLogoutHandler.mutate {
                $0 = true
            }
        })
        sut.logoutButtonTapped()
        if connected {
            try await waitUntil(!didCallLogoutHandler)
            #expect(preferenceUseCase["offlineLogOutWarningDismissed"] == false)
        } else {
            try await Task.sleep(nanoseconds: 1_000_000_000)
        }
        #expect(didCallLogoutHandler == connected)
    }

    private func makeSUT(
        router: some AccountMenuViewRouting = MockMenuViewRouter(),
        tracker: some AnalyticsTracking = MockTracker(),
        accountUseCase: some AccountUseCaseProtocol =  MockAccountUseCase(
            currentAccountDetails: MockMEGAAccountDetails(type: .free).toAccountDetailsEntity(),
            email: "test@test.com",
            rubbishBinStorage: 0
        ),
        preferenceUseCase: some PreferenceUseCaseProtocol = MockPreferenceUseCase(),
        networkMonitorUseCase: some NetworkMonitorUseCaseProtocol = MockNetworkMonitorUseCase(),
        logoutHandler: @escaping () async -> Void = {}
    ) -> AccountMenuViewModel {
        let currentUserSource = CurrentUserSource(sdk: MockSdk())
        return AccountMenuViewModel(
            router: router,
            currentUserSource: currentUserSource,
            tracker: tracker,
            accountUseCase: accountUseCase,
            userImageUseCase: MockUserImageUseCase(),
            megaHandleUseCase: MockMEGAHandleUseCase(),
            networkMonitorUseCase: networkMonitorUseCase,
            preferenceUseCase: preferenceUseCase,
            fullNameHandler: { _ in "" },
            avatarFetchHandler: { _, _ in UIImage() },
            logoutHandler: logoutHandler
        )
    }

    private func waitUntil(
        timeout: TimeInterval = 2.0,
        _ condition: @Sendable @autoclosure @escaping () async -> Bool
    ) async throws {
        try await withTimeout(seconds: timeout) {
            while await condition() {
                try await Task.sleep(nanoseconds: 10_000_000) // 10ms
            }
        }
    }
}

private final class MockMenuViewRouter: AccountMenuViewRouting {
    private(set) var showNotifications_calledTimes = 0
    private(set) var showAccount_calledTimes = 0
    private(set) var upgradeAccount_calledTimes = 0
    private(set) var showStorage_calledTimes = 0
    private(set) var showContacts_calledTimes = 0
    private(set) var showAchievements_calledTimes = 0
    private(set) var showSharedItems_calledTimes = 0
    private(set) var showDeviceCentre_calledTimes = 0
    private(set) var showTransfers_calledTimes = 0
    private(set) var showOfflineFiles_calledTimes = 0
    private(set) var showRubbishBin_calledTimes = 0
    private(set) var showSettings_calledTimes = 0
    private(set) var openLink_calledTimes = 0
    private(set) var openLink_lastApp: Accounts.MegaCompanionApp?

    func showNotifications() {
        showNotifications_calledTimes += 1
    }

    func showAccount() {
        showAccount_calledTimes += 1
    }

    func upgradeAccount() {
        upgradeAccount_calledTimes += 1
    }

    func showStorage() {
        showStorage_calledTimes += 1
    }

    func showContacts() {
        showContacts_calledTimes += 1
    }

    func showAchievements() {
        showAchievements_calledTimes += 1
    }

    func showSharedItems() {
        showSharedItems_calledTimes += 1
    }

    func showDeviceCentre() {
        showDeviceCentre_calledTimes += 1
    }

    func showTransfers() {
        showTransfers_calledTimes += 1
    }

    func showOfflineFiles() {
        showOfflineFiles_calledTimes += 1
    }

    func showRubbishBin() {
        showRubbishBin_calledTimes += 1
    }

    func showSettings() {
        showSettings_calledTimes += 1
    }

    func openLink(for app: Accounts.MegaCompanionApp) {
        openLink_calledTimes += 1
        openLink_lastApp = app
    }
}
