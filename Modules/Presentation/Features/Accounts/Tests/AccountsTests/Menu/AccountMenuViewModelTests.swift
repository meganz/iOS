@testable import Accounts
import Combine
import MEGAAnalyticsiOS
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
struct AccountMenuViewModelTests {
    struct TestEventTrackingData: @unchecked Sendable {
        let section: AccountMenuSectionType
        let row: Int
        let expectedEventIdentifier: any EventIdentifier
    }

    @Test("Test init method")
    func testInit() {
        let sut = makeSUT()
        #expect(sut.isAtTop == true)
        #expect(Set(sut.sections.keys) == Set([.account, .tools, .privacySuite]))
        #expect(sut.isPrivacySuiteExpanded == false)
    }

    @Test("Test for account row data")
    func testAccountRowData() throws {
        let accountUseCase = MockAccountUseCase(email: "email@test.com")
        let sut = makeSUT(accountUseCase: accountUseCase)
        let accountSection = sut.sections[.account]
        let accountRowData = try #require(
            accountSection?[SUT.Constants.AccountSectionIndex.accountDetails.rawValue],
            "Account section should contain account details"
        )
        #expect(accountRowData.title == "")
        #expect(accountRowData.subtitleState == .value("email@test.com"))
        #expect(accountRowData.rowType == .disclosure(action: {}))
        #expect(accountRowData.iconConfiguration.style == .rounded)
    }

    @Test("Test for plan row data")
    func testPlanRowData() throws {
        let accountUseCase = MockAccountUseCase(currentAccountDetails: MockMEGAAccountDetails(type: .proI).toAccountDetailsEntity())
        let sut = makeSUT(accountUseCase: accountUseCase)
        let accountSection = sut.sections[.account]
        let planRowData = try #require(
            accountSection?[SUT.Constants.AccountSectionIndex.currentPlan.rawValue],
            "Account section should contain current plan"
        )
        #expect(planRowData.title == Strings.Localizable.InAppPurchase.ProductDetail.Navigation.currentPlan)
        #expect(
            planRowData.subtitleState == .value(
                MockMEGAAccountDetails(type: .proI)
                    .toAccountDetailsEntity()
                    .proLevel
                    .toAccountTypeDisplayName()
            )
        )
        #expect(planRowData.rowType == .withButton(title: Strings.Localizable.upgrade, action: { }))
        #expect(planRowData.iconConfiguration.style == .normal)
    }

    @Test("Test for storage row data")
    func testStorageRowData() throws {
        let accountUseCase = MockAccountUseCase(
            currentAccountDetails: MockMEGAAccountDetails(storageUsed: 10, storageMax: 100, type: .proI)
                .toAccountDetailsEntity()
        )
        let sut = makeSUT(accountUseCase: accountUseCase)
        let accountSection = sut.sections[.account]
        let storageRowData = try #require(
            accountSection?[SUT.Constants.AccountSectionIndex.storageUsed.rawValue],
            "Account section should contain storage used"
        )
        #expect(storageRowData.title == Strings.Localizable.storage)
        #expect(storageRowData.subtitleState == .value("10 B / 100 B"))
        #expect(storageRowData.rowType == .disclosure(action: {}))
        #expect(storageRowData.iconConfiguration.style == .normal)
    }

    @Test("Test contacts row data")
    func testContactsRowData() throws {
        let sut = makeSUT()
        let accountSection = sut.sections[.account]
        let contactsRowData = try #require(
            accountSection?[SUT.Constants.AccountSectionIndex.contacts.rawValue],
            "Account section should contain contacts"
        )
        #expect(contactsRowData.title == Strings.Localizable.contactsTitle)
        #expect(contactsRowData.subtitleState == nil)
        #expect(contactsRowData.rowType == .disclosure(action: {}))
        #expect(contactsRowData.iconConfiguration.style == .normal)
    }

    @Test("Test achievements row data")
    func testAchievementsRowData() throws {
        let sut = makeSUT()
        let accountSection = sut.sections[.account]
        let achievementsRowData = try #require(
            accountSection?[SUT.Constants.AccountSectionIndex.achievements.rawValue],
            "Account section should contain achievements"
        )
        #expect(achievementsRowData.title == Strings.Localizable.achievementsTitle)
        #expect(achievementsRowData.subtitleState == nil)
        #expect(achievementsRowData.rowType == .disclosure(action: {}))
        #expect(achievementsRowData.iconConfiguration.style == .normal)
    }

    @Test("Test shared items row data")
    func testSharedItemsRowData() throws {
        let sut = makeSUT()
        let toolsSection = sut.sections[.tools]
        let sharedItemsRowData = try #require(
            toolsSection?[SUT.Constants.ToolsSectionIndex.sharedItems.rawValue],
            "Tools section should contain shared items"
        )
        #expect(sharedItemsRowData.title == Strings.Localizable.sharedItems)
        #expect(sharedItemsRowData.subtitleState == nil)
        #expect(sharedItemsRowData.rowType == .disclosure(action: {}))
        #expect(sharedItemsRowData.iconConfiguration.style == .normal)
    }

    @Test("Test device center row data")
    func testDeviceCenterRowData() throws {
        let sut = makeSUT()
        let toolsSection = sut.sections[.tools]
        let deviceCenterRowData = try #require(
            toolsSection?[SUT.Constants.ToolsSectionIndex.deviceCentre.rawValue],
            "Tools section should contain device center"
        )
        #expect(deviceCenterRowData.title == Strings.Localizable.Device.Center.title)
        #expect(deviceCenterRowData.subtitleState == nil)
        #expect(deviceCenterRowData.rowType == .disclosure(action: {}))
        #expect(deviceCenterRowData.iconConfiguration.style == .normal)
    }

    @Test("Test transfers row data")
    func testTransfersRowData() throws {
        let sut = makeSUT()
        let toolsSection = sut.sections[.tools]
        let transfersRowData = try #require(
            toolsSection?[SUT.Constants.ToolsSectionIndex.transfers.rawValue],
            "Tools section should contain transfers"
        )
        #expect(transfersRowData.title == Strings.Localizable.transfers)
        #expect(transfersRowData.subtitleState == nil)
        #expect(transfersRowData.rowType == .disclosure(action: {}))
        #expect(transfersRowData.iconConfiguration.style == .normal)
    }

    @Test("Test offline files row data")
    func testOfflineFilesRowData() throws {
        let sut = makeSUT()
        let toolsSection = sut.sections[.tools]
        let offlineFilesRowData = try #require(
            toolsSection?[SUT.Constants.ToolsSectionIndex.offlineFiles.rawValue],
            "Tools section should contain offline files"
        )
        #expect(offlineFilesRowData.title == Strings.Localizable.AccountMenu.offlineFiles)
        #expect(offlineFilesRowData.subtitleState == nil)
        #expect(offlineFilesRowData.rowType == .disclosure(action: {}))
        #expect(offlineFilesRowData.iconConfiguration.style == .normal)
    }

    @Test("Test rubbish bin row data")
    func testRubbishBinRowData() throws {
        let accountUseCase = MockAccountUseCase(rubbishBinStorage: 200)
        let sut = makeSUT(accountUseCase: accountUseCase)
        let toolsSection = sut.sections[.tools]
        let rubbishBinRowData = try #require(
            toolsSection?[SUT.Constants.ToolsSectionIndex.rubbishBin.rawValue],
            "Tools section should contain rubbish bin"
        )
        #expect(rubbishBinRowData.title == Strings.Localizable.rubbishBinLabel)
        #expect(rubbishBinRowData.subtitleState == .value("200 B"))
        #expect(rubbishBinRowData.rowType == .disclosure(action: {}))
        #expect(rubbishBinRowData.iconConfiguration.style == .normal)
    }

    @Test("Test settings row data")
    func testSettingsRowData() throws {
        let sut = makeSUT()
        let toolsSection = sut.sections[.tools]
        let settingsRowData = try #require(
            toolsSection?[SUT.Constants.ToolsSectionIndex.settings.rawValue],
            "Tools section should contain settings"
        )
        #expect(settingsRowData.title == Strings.Localizable.settingsTitle)
        #expect(settingsRowData.subtitleState == nil)
        #expect(settingsRowData.rowType == .disclosure(action: {}))
        #expect(settingsRowData.iconConfiguration.style == .normal)
    }

    @Test("Test VPN app row data")
    func testVPNAPPRowData() throws {
        let sut = makeSUT()
        let privacySuiteSection = sut.sections[.privacySuite]
        let megaVPNAppRowData =  try #require(
            privacySuiteSection?[SUT.Constants.PrivacySuiteSectionIndex.vpnApp.rawValue],
            "Privacy Suite section should contain vpn app",
        )
        #expect(megaVPNAppRowData.title == Strings.Localizable.AccountMenu.MegaVPN.buttonTitle)
        #expect(megaVPNAppRowData.subtitleState == .value(Strings.Localizable.AccountMenu.MegaVPN.buttonSubtitle))
        #expect(megaVPNAppRowData.rowType == .externalLink(action: {}))
        #expect(megaVPNAppRowData.iconConfiguration.style == .normal)
    }

    @Test("Test Pass app row data")
    func testPassAppRowData() throws {
        let sut = makeSUT()
        let privacySuiteSection = sut.sections[.privacySuite]
        let passRowData = try #require(
            privacySuiteSection?[SUT.Constants.PrivacySuiteSectionIndex.pwmApp.rawValue],
            "Privacy Suite section should contain pwm app"
        )
        #expect(passRowData.title == Strings.Localizable.AccountMenu.MegaPass.buttonTitle)
        #expect(passRowData.subtitleState == .value(Strings.Localizable.AccountMenu.MegaPass.buttonSubtitle))
        #expect(passRowData.rowType == .externalLink(action: {}))
        #expect(passRowData.iconConfiguration.style == .normal)
    }

    @Test("Test transfer it app row data")
    func testTransferAppRowData() throws {
        let sut = makeSUT()
        let privacySuiteSection = sut.sections[.privacySuite]
        let transferItAppRowData = try #require(
            privacySuiteSection?[SUT.Constants.PrivacySuiteSectionIndex.transferItApp.rawValue],
            "Privacy Suite section should contain transfer.it app"
        )
        #expect(transferItAppRowData.title == Strings.Localizable.AccountMenu.TransferIt.buttonTitle)
        #expect(transferItAppRowData.subtitleState == .value(Strings.Localizable.AccountMenu.TransferIt.buttonSubtitle))
        #expect(transferItAppRowData.rowType == .externalLink(action: {}))
        #expect(transferItAppRowData.iconConfiguration.style == .normal)
    }

    @Test("Test refresh account details")
    func testRefreshAccountDetails() async throws {
        let accountUseCase = MockAccountUseCase(
            currentAccountDetails: MockMEGAAccountDetails(storageUsed: 10, storageMax: 100, type: .proI)
                .toAccountDetailsEntity(),
            accountDetailsResult: .success(MockMEGAAccountDetails(storageUsed: 20, storageMax: 200, type: .proII)
                .toAccountDetailsEntity())
        )

        let sut = makeSUT(accountUseCase: accountUseCase)
        await sut.onTask()

        let accountSection = sut.sections[.account]
        let planRowData = try #require(
            accountSection?[SUT.Constants.AccountSectionIndex.currentPlan.rawValue],
            "Account section should contain current plan details"
        )

        #expect(
            planRowData.subtitleState == .value(
                MockMEGAAccountDetails(type: .proII)
                    .toAccountDetailsEntity()
                    .proLevel
                    .toAccountTypeDisplayName()
            )
        )

        let storageRowData = try #require(
            accountSection?[SUT.Constants.AccountSectionIndex.storageUsed.rawValue],
            "Account section should contain storage details"
        )
        #expect(storageRowData.title == Strings.Localizable.storage)
        #expect(storageRowData.subtitleState == .value("20 B / 200 B"))
    }

    @Test("Test account details tap")
    func testAccountDetailsTap() throws {
        let router = MockMenuViewRouter()
        let sut = makeSUT(router: router)
        let accountSection = try #require(sut.sections[.account], "Account section should exist")
        let accountInfoRow = try #require(
            accountSection[SUT.Constants.AccountSectionIndex.accountDetails.rawValue],
            "Account section should have at least one row"
        )

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
        let currentPlanRow = try #require(
            accountSection[SUT.Constants.AccountSectionIndex.currentPlan.rawValue],
            "Account section should contain current plan details"
        )

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
        let storageRow = try #require(
            accountSection[SUT.Constants.AccountSectionIndex.storageUsed.rawValue],
            "Account section should contain storage details"
        )

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
        let contactsRow = try #require(
            accountSection[SUT.Constants.AccountSectionIndex.contacts.rawValue],
            "Account section should contain contacts"
        )

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
        let achievementsRow = try #require(
            accountSection[SUT.Constants.AccountSectionIndex.achievements.rawValue],
            "Account section should contain achievements"
        )

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
        let sharedItemsRow = try #require(
            toolsSection[SUT.Constants.ToolsSectionIndex.sharedItems.rawValue],
            "Tools section should contain shared items"
        )

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
        let deviceCenterRow = try #require(
            toolsSection[SUT.Constants.ToolsSectionIndex.deviceCentre.rawValue],
            "Tools section should contain device center"
        )

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
        let transfersRow = try #require(
            toolsSection[SUT.Constants.ToolsSectionIndex.transfers.rawValue],
            "Tools section should contain transfers"
        )

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
        let offlineFilesRow = try #require(
            toolsSection[SUT.Constants.ToolsSectionIndex.offlineFiles.rawValue],
            "Tools section should contain offline files"
        )

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
        let rubbishBinRow = try #require(
            toolsSection[SUT.Constants.ToolsSectionIndex.rubbishBin.rawValue],
            "Tools section should contain rubbish bin"
        )

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
        let settingsRow = try #require(
            toolsSection[SUT.Constants.ToolsSectionIndex.settings.rawValue],
            "Tools section should contain settings"
        )

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
        let vpnRow = try #require(
            privacySection[SUT.Constants.PrivacySuiteSectionIndex.vpnApp.rawValue],
            "Privacy section should contain at least one row"
        )

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
        let passRow = try #require(
            privacySection[SUT.Constants.PrivacySuiteSectionIndex.pwmApp.rawValue],
            "Privacy section should contain at least one row"
        )

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
        let transferItRow = try #require(
            privacySection[SUT.Constants.PrivacySuiteSectionIndex.transferItApp.rawValue],
            "Privacy section should contain at least one row"
        )

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

    @Test("Test app notifications count logic with valid number of app notifications")
    func testAppNotificationsCount_withValidNumberOfNotifications() async throws {
        let notificationUseCase = MockNotificationUseCase(unreadNotificationIDs: [100, 200, 300, 400, 500])
        let accountUseCase = MockAccountUseCase(relevantUnseenUserAlertsCount: 15)
        let sut = makeSUT(accountUseCase: accountUseCase, notificationsUseCase: notificationUseCase)
        try await waitUntil(await MainActor.run { sut.appNotificationsCount != 20 })
        #expect(sut.appNotificationsCount == 20)
    }

    @Test("Test app notifications count logic with no app notifications")
    func testAppNotificationsCount_withNoAppNotifications() {
        let notificationUseCase = MockNotificationUseCase(unreadNotificationIDs: [])
        let accountUseCase = MockAccountUseCase(relevantUnseenUserAlertsCount: 0)
        let sut = makeSUT(accountUseCase: accountUseCase, notificationsUseCase: notificationUseCase)
        #expect(sut.appNotificationsCount == 0)
    }

    @Test("Test the shared items notifications count logic with valid number of notifications")
    func testSharedItemsNotificationsCount_withValidNumberOfNotifications() throws {
        let sut = makeSUT(sharedItemsNotificationCountHandler: { 10 })
        #expect(sut.sections[.tools]?[SUT.Constants.ToolsSectionIndex.sharedItems.rawValue]?.notificationCount == 10)
    }

    @Test("Test the shared items notifications count logic with no notifications")
    func testSharedItemsNotificationsCount_withNoNotifications() throws {
        let sut = makeSUT(sharedItemsNotificationCountHandler: { 0 })
        #expect(sut.sections[.tools]?[SUT.Constants.ToolsSectionIndex.sharedItems.rawValue]?.notificationCount == nil)
    }

    @Test("Test the contacts notifications count logic with valid number of contact requests")
    func testContactsNotificationCount_withValidContactRequests() throws {
        let accountUseCase = MockAccountUseCase(incomingContactsRequestsCount: 30)
        let sut = makeSUT(accountUseCase: accountUseCase)
        #expect(sut.sections[.account]?[SUT.Constants.AccountSectionIndex.contacts.rawValue]?.notificationCount == 30)
    }

    @Test("Test the contacts notifications count logic with 0 contact requests")
    func testContactsNotificationCount_withNoContactRequests() throws {
        let accountUseCase = MockAccountUseCase(incomingContactsRequestsCount: 0)
        let sut = makeSUT(accountUseCase: accountUseCase)
        #expect(sut.sections[.account]?[SUT.Constants.AccountSectionIndex.contacts.rawValue]?.notificationCount == nil)
    }

    @Test("Test the upgrade plan menu option logic for business account")
    func testUpgradePlanMenuOption_forBusinessAccount_shouldHideOption() {
        let accountUseCase = MockAccountUseCase(
            currentAccountDetails: MockMEGAAccountDetails(type: .business).toAccountDetailsEntity()
        )
        let sut = makeSUT(accountUseCase: accountUseCase)
        #expect(
            sut
                .sections[.account]?[SUT.Constants.AccountSectionIndex.currentPlan.rawValue]?
                .title != Strings.Localizable.InAppPurchase.ProductDetail.Navigation.currentPlan
        )
    }

    @Test("Test the upgrade plan menu option logic for pro flexi account")
    func testUpgradePlanMenuOption_forProFlexiAccount_shouldHideOption() {
        let accountUseCase = MockAccountUseCase(
            currentAccountDetails: MockMEGAAccountDetails(type: .proFlexi).toAccountDetailsEntity()
        )
        let sut = makeSUT(accountUseCase: accountUseCase)
        #expect(
            sut
                .sections[.account]?[SUT.Constants.AccountSectionIndex.currentPlan.rawValue]?
                .title != Strings.Localizable.InAppPurchase.ProductDetail.Navigation.currentPlan
        )
    }

    @Test("Test On AccountRequest Finish handler when account details changed")
    func testOnAccountRequestFinish_whenAccountDetailsChanged() async throws {
        let (stream, continuation) = AsyncStream<Result<AccountRequestEntity, any Error>>.makeStream()
        let accountUseCase = MockAccountUseCase(
            currentAccountDetails: MockMEGAAccountDetails(type: .free).toAccountDetailsEntity(),
            onAccountRequestFinish: stream.eraseToAnyAsyncSequence()
        )
        var showUpdatedValue = false
        let fullNameHandler: (CurrentUserSource) -> String = { _ in
            if showUpdatedValue {
                showUpdatedValue.toggle()
                return "initialName"
            } else {
                return "updatedName"
            }

        }
        let sut = makeSUT(accountUseCase: accountUseCase, fullNameHandler: fullNameHandler)
        accountUseCase.update(email: "testEmail@test.com")
        continuation.yield(.success(.init(type: .accountDetails)))
        try await waitUntil(
            await MainActor.run {
                sut
                    .sections[.account]?[SUT.Constants.AccountSectionIndex.accountDetails.rawValue]?
                    .title != "updatedName"
            }
        )
        #expect(
            sut
                .sections[.account]?[SUT.Constants.AccountSectionIndex.accountDetails.rawValue]?
                .subtitleState == .value("testEmail@test.com")
        )
        #expect(
            sut.sections[.account]?[SUT.Constants.AccountSectionIndex.accountDetails.rawValue]?
                .title == "updatedName"
        )
    }

    @Test("Test On AccountRequest Finish handler when user attribute changed")
    func testOnAccountRequestFinish_whenUserAttributeChanged() async throws {
        let (stream, continuation) = AsyncStream<Result<AccountRequestEntity, any Error>>.makeStream()
        let accountDetails = MockMEGAAccountDetails(type: .free).toAccountDetailsEntity()
        let accountUseCase = MockAccountUseCase(
            currentAccountDetails: accountDetails,
            accountDetailsResult: .success(accountDetails),
            onAccountRequestFinish: stream.eraseToAnyAsyncSequence()
        )
        var showUpdatedValue = false
        let fullNameHandler: (CurrentUserSource) -> String = { _ in
            if showUpdatedValue {
                showUpdatedValue.toggle()
                return "initialName"
            } else {
                return "updatedName"
            }

        }
        let sut = makeSUT(accountUseCase: accountUseCase, fullNameHandler: fullNameHandler)
        continuation.yield(.success(.init(type: .getAttrUser, userAttribute: .firstName)))
        try await waitUntil(
            await MainActor.run {
                sut
                    .sections[.account]?[SUT.Constants.AccountSectionIndex.accountDetails.rawValue]?
                    .title != "updatedName"
            }
        )
        #expect(
            sut
                .sections[.account]?[SUT.Constants.AccountSectionIndex.accountDetails.rawValue]?
                .subtitleState == .loading
        )
        #expect(
            sut
                .sections[.account]?[SUT.Constants.AccountSectionIndex.accountDetails.rawValue]?
                .title == "updatedName"
        )
    }

    @Test("Test contacts request listener updates")
    func testOnContactRequestsUpdates() async throws {
        let (stream, continuation) = AsyncStream<[ContactRequestEntity]>.makeStream()
        let accountUseCase = MockAccountUseCase(onContactRequestsUpdates: stream.eraseToAnyAsyncSequence())
        let sut = makeSUT(accountUseCase: accountUseCase)
        accountUseCase.update(incomingContactsRequestsCount: 10)
        continuation.yield([ContactRequestEntity.random])
        try await waitUntil(
            await MainActor.run {
                sut
                    .sections[.account]?[SUT.Constants.AccountSectionIndex.contacts.rawValue]?.notificationCount != 10
            }
        )
        #expect(
            sut.sections[.account]?[SUT.Constants.AccountSectionIndex.contacts.rawValue]?.notificationCount == 10
        )
    }

    @Test("Test on user alerts updates")
    func testOnUserAlertsUpdates() async throws {
        let (stream, continuation) = AsyncStream<[UserAlertEntity]>.makeStream()
        let notificationUseCase = MockNotificationUseCase(unreadNotificationIDs: [10, 20])
        let accountUseCase = MockAccountUseCase(relevantUnseenUserAlertsCount: 28, onUserAlertsUpdates: stream.eraseToAnyAsyncSequence())
        let sut = makeSUT(accountUseCase: accountUseCase, notificationsUseCase: notificationUseCase)
        continuation.yield([UserAlertEntity.random])
        try await waitUntil(await MainActor.run { sut.appNotificationsCount != 30 })
        #expect(sut.appNotificationsCount == 30)
    }

    @Test(arguments: [
        (MockAccountUseCase(
            currentAccountDetails: MockMEGAAccountDetails(
                storageUsed: 10,
                storageMax: 20,
                type: .free
            ).toAccountDetailsEntity()
        ), AccountMenuOption.TextLoadState.value("10 B / 20 B")),
        (MockAccountUseCase(currentAccountDetails: nil), nil)
    ])
    func testIsAccountUpdating(accountUseCase: MockAccountUseCase, initialState: AccountMenuOption.TextLoadState) async throws {
        let monitorSubmitReceiptPublisher = PassthroughSubject<Bool, Never>()
        let purchaseUseCase = MockAccountPlanPurchaseUseCase(
            monitorSubmitReceiptPublisher: monitorSubmitReceiptPublisher.eraseToAnyPublisher()
        )
        let sut = makeSUT(accountUseCase: accountUseCase, purchaseUseCase: purchaseUseCase)
        let accountSection = sut.sections[.account]

        #expect(sut.isAccountUpdating == false)

        let storageRowData = try #require(
            accountSection?[SUT.Constants.AccountSectionIndex.storageUsed.rawValue],
            "Account section should contain storage used"
        )
        #expect(storageRowData.subtitleState == initialState)

        try await waitUntil(
            await MainActor.run {
                purchaseUseCase.monitorSubmitReceiptPublisherCalled == 0
            }
        )
        monitorSubmitReceiptPublisher.send(true)
        try await waitUntil(
            await MainActor.run {
                sut.isAccountUpdating == false
            }
        )
        #expect(sut.isAccountUpdating)

        let updatedAccountSection = sut.sections[.account]
        let updatedStorageRowData = try #require(
            updatedAccountSection?[SUT.Constants.AccountSectionIndex.storageUsed.rawValue],
            "Account section should contain storage used"
        )
        #expect(updatedStorageRowData.subtitleState == .loading)
    }

    @Test(
        arguments: [
            TestEventTrackingData(
                section: .account,
                row: SUT.Constants.AccountSectionIndex.accountDetails.rawValue,
                expectedEventIdentifier: MyAccountProfileNavigationItemEvent()
            ),
            TestEventTrackingData(
                section: .account,
                row: SUT.Constants.AccountSectionIndex.storageUsed.rawValue,
                expectedEventIdentifier: MyMenuStorageNavigationItemEvent()
            ),
            TestEventTrackingData(
                section: .account,
                row: SUT.Constants.AccountSectionIndex.contacts.rawValue,
                expectedEventIdentifier: MyMenuContactsNavigationItemEvent()
            ),
            TestEventTrackingData(
                section: .account,
                row: SUT.Constants.AccountSectionIndex.achievements.rawValue,
                expectedEventIdentifier: MyMenuAchievementsNavigationItemEvent()
            ),
            TestEventTrackingData(
                section: .tools,
                row: SUT.Constants.ToolsSectionIndex.sharedItems.rawValue,
                expectedEventIdentifier: MyMenuSharedItemsNavigationItemEvent()
            ),
            TestEventTrackingData(
                section: .tools,
                row: SUT.Constants.ToolsSectionIndex.deviceCentre.rawValue,
                expectedEventIdentifier: MyMenuDeviceCentreNavigationItemEvent()
            ),
            TestEventTrackingData(
                section: .tools,
                row: SUT.Constants.ToolsSectionIndex.transfers.rawValue,
                expectedEventIdentifier: MyMenuTransfersNavigationItemEvent()
            ),
            TestEventTrackingData(
                section: .tools,
                row: SUT.Constants.ToolsSectionIndex.offlineFiles.rawValue,
                expectedEventIdentifier: MyMenuOfflineFilesNavigationItemEvent()
            ),
            TestEventTrackingData(
                section: .tools,
                row: SUT.Constants.ToolsSectionIndex.rubbishBin.rawValue,
                expectedEventIdentifier: MyMenuRubbishBinNavigationItemEvent()
            ),
            TestEventTrackingData(
                section: .tools,
                row: SUT.Constants.ToolsSectionIndex.settings.rawValue,
                expectedEventIdentifier: MyMenuSettingsNavigationItemEvent()
            )
        ]
    )
    func testDisclosureButtonAnalyticsEvents(testcase: TestEventTrackingData) {
        let tracker = MockTracker()
        let sut = makeSUT(tracker: tracker)
        let section = sut.sections[testcase.section]
        if case .disclosure(let action) = section?[testcase.row]?.rowType {
            action()
            Test.assertTrackAnalyticsEventCalled(
                trackedEventIdentifiers: tracker.trackedEventIdentifiers,
                with: [testcase.expectedEventIdentifier]
            )
        }
    }

    func testUpgradeAnalyticsEvent(data: TestEventTrackingData) {
        let tracker = MockTracker()
        let sut = makeSUT(tracker: tracker)
        let accountSection = sut.sections[.account]
        if case .withButton(_, let action) = accountSection?[SUT.Constants.AccountSectionIndex.currentPlan.rawValue]?.rowType {
            action()
            Test.assertTrackAnalyticsEventCalled(
                trackedEventIdentifiers: tracker.trackedEventIdentifiers,
                with: [UpgradeMyAccountEvent()]
            )
        }
    }

    @Test(
        arguments: [
            TestEventTrackingData(
                section: .privacySuite,
                row: SUT.Constants.PrivacySuiteSectionIndex.vpnApp.rawValue,
                expectedEventIdentifier: MyMenuMEGAVPNNavigationItemEvent()
            ),
            TestEventTrackingData(
                section: .privacySuite,
                row: SUT.Constants.PrivacySuiteSectionIndex.pwmApp.rawValue,
                expectedEventIdentifier: MyMenuMEGAPassNavigationItemEvent()
            ),
            TestEventTrackingData(
                section: .privacySuite,
                row: SUT.Constants.PrivacySuiteSectionIndex.transferItApp.rawValue,
                expectedEventIdentifier: MyMenuTransfersNavigationItemEvent()
            )
        ]
    )
    func testExternalLinksAnalyticsEvent(testcase: TestEventTrackingData) {
        let tracker = MockTracker()
        let sut = makeSUT(tracker: tracker)
        let section = sut.sections[testcase.section]
        if case .externalLink(let action) = section?[testcase.row]?.rowType {
            action()
            Test.assertTrackAnalyticsEventCalled(
                trackedEventIdentifiers: tracker.trackedEventIdentifiers,
                with: [testcase.expectedEventIdentifier]
            )
        }
    }

    @Test("Test for all read notification event when view appears")
    func testForUnreadNotificationEvent() async {
        let tracker = MockTracker()
        let sut = makeSUT(tracker: tracker)
        await sut.onTask()
        Test.assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [AccountNotificationCentreDisplayedWithNoUnreadNotificationsEvent()]
        )
    }

    @Test("Test for unread notification event when view appears")
    func testForReadNotificationEvent() async {
        let tracker = MockTracker()
        let notificationUseCase = MockNotificationUseCase(unreadNotificationIDs: [100, 200, 300, 400, 500])
        let sut = makeSUT(tracker: tracker, notificationsUseCase: notificationUseCase)
        await sut.onTask()
        Test.assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [AccountNotificationCentreDisplayedWithUnreadNotificationsEvent()]
        )
    }

    private typealias SUT = AccountMenuViewModel

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
        notificationsUseCase: some NotificationsUseCaseProtocol = MockNotificationUseCase(),
        purchaseUseCase: some AccountPlanPurchaseUseCaseProtocol = MockAccountPlanPurchaseUseCase(),
        logoutHandler: @escaping () async -> Void = {},
        sharedItemsNotificationCountHandler: @escaping () -> Int = { 0 },
        fullNameHandler: @escaping (CurrentUserSource) -> String = { _ in "" }
    ) -> SUT {
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
            notificationsUseCase: notificationsUseCase,
            purchaseUseCase: purchaseUseCase,
            fullNameHandler: fullNameHandler,
            avatarFetchHandler: { _, _ in UIImage() },
            logoutHandler: logoutHandler,
            sharedItemsNotificationCountHandler: sharedItemsNotificationCountHandler
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

extension AccountMenuOption.TextLoadState: Equatable {
    public static func == (lhs: AccountMenuOption.TextLoadState, rhs: AccountMenuOption.TextLoadState) -> Bool {
        switch (lhs, rhs) {
        case (.none, .none), (.loading, .loading):
            return true
        case let (.value(l), .value(r)):
            return l == r
        default:
            return false
        }
    }
}
