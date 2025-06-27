@testable import Accounts
import MEGAAppSDKRepo
import MEGAAppSDKRepoMock
import MEGADomain
import MEGADomainMock
import MEGAL10n
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
        #expect(accountRowData?.rowType == .disclosure)
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
        #expect(storageRowData?.rowType == .disclosure)
        #expect(storageRowData?.iconConfiguration.style == .normal)
    }

    @Test("Test contacts row data")
    func testContactsRowData() {
        let sut = makeSUT()
        let accountSection = sut.sections[.account]
        let contactsRowData = accountSection?[3]
        #expect(contactsRowData?.title == Strings.Localizable.contactsTitle)
        #expect(contactsRowData?.subtitle == nil)
        #expect(contactsRowData?.rowType == .disclosure)
        #expect(contactsRowData?.iconConfiguration.style == .normal)
    }

    @Test("Test achievements row data")
    func testAchievementsRowData() {
        let sut = makeSUT()
        let accountSection = sut.sections[.account]
        let achievementsRowData = accountSection?[4]
        #expect(achievementsRowData?.title == Strings.Localizable.achievementsTitle)
        #expect(achievementsRowData?.subtitle == nil)
        #expect(achievementsRowData?.rowType == .disclosure)
        #expect(achievementsRowData?.iconConfiguration.style == .normal)
    }

    @Test("Test shared items row data")
    func testSharedItemsRowData() {
        let sut = makeSUT()
        let toolsSection = sut.sections[.tools]
        let sharedItemsRowData = toolsSection?[0]
        #expect(sharedItemsRowData?.title == Strings.Localizable.sharedItems)
        #expect(sharedItemsRowData?.subtitle == nil)
        #expect(sharedItemsRowData?.rowType == .disclosure)
        #expect(sharedItemsRowData?.iconConfiguration.style == .normal)
    }

    @Test("Test device center row data")
    func testDeviceCenterRowData() {
        let sut = makeSUT()
        let toolsSection = sut.sections[.tools]
        let deviceCenterRowData = toolsSection?[1]
        #expect(deviceCenterRowData?.title == Strings.Localizable.Device.Center.title)
        #expect(deviceCenterRowData?.subtitle == nil)
        #expect(deviceCenterRowData?.rowType == .disclosure)
        #expect(deviceCenterRowData?.iconConfiguration.style == .normal)
    }

    @Test("Test transfers row data")
    func testTransfersRowData() {
        let sut = makeSUT()
        let toolsSection = sut.sections[.tools]
        let transfersRowData = toolsSection?[2]
        #expect(transfersRowData?.title == Strings.Localizable.transfers)
        #expect(transfersRowData?.subtitle == nil)
        #expect(transfersRowData?.rowType == .disclosure)
        #expect(transfersRowData?.iconConfiguration.style == .normal)
    }

    @Test("Test offline files row data")
    func testOfflineFilesRowData() {
        let sut = makeSUT()
        let toolsSection = sut.sections[.tools]
        let offlineFilesRowData = toolsSection?[3]
        #expect(offlineFilesRowData?.title == Strings.Localizable.AccountMenu.offlineFiles)
        #expect(offlineFilesRowData?.subtitle == nil)
        #expect(offlineFilesRowData?.rowType == .disclosure)
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
        #expect(rubbishBinRowData?.rowType == .disclosure)
        #expect(rubbishBinRowData?.iconConfiguration.style == .normal)
    }

    @Test("Test settings row data")
    func testSettingsRowData() {
        let sut = makeSUT()
        let toolsSection = sut.sections[.tools]
        let settingsRowData = toolsSection?[5]
        #expect(settingsRowData?.title == Strings.Localizable.settingsTitle)
        #expect(settingsRowData?.subtitle == nil)
        #expect(settingsRowData?.rowType == .disclosure)
        #expect(settingsRowData?.iconConfiguration.style == .normal)
    }

    @Test("Test VPN app row data")
    func testVPNAPPRowData() {
        let sut = makeSUT()
        let privacySuiteSection = sut.sections[.privacySuite]
        let megaVPNAppRowData = privacySuiteSection?[0]
        #expect(megaVPNAppRowData?.title == Strings.Localizable.AccountMenu.MegaVPN.buttonTitle)
        #expect(megaVPNAppRowData?.subtitle == Strings.Localizable.AccountMenu.MegaVPN.buttonSubtitle)
        #expect(megaVPNAppRowData?.rowType == .externalLink)
        #expect(megaVPNAppRowData?.iconConfiguration.style == .normal)
    }

    @Test("Test Pass app row data")
    func testPassAppRowData() {
        let sut = makeSUT()
        let privacySuiteSection = sut.sections[.privacySuite]
        let passRowData = privacySuiteSection?[1]
        #expect(passRowData?.title == Strings.Localizable.AccountMenu.MegaPass.buttonTitle)
        #expect(passRowData?.subtitle == Strings.Localizable.AccountMenu.MegaPass.buttonSubtitle)
        #expect(passRowData?.rowType == .externalLink)
        #expect(passRowData?.iconConfiguration.style == .normal)
    }

    @Test("Test transfer it app row data")
    func testTransferAppRowData() {
        let sut = makeSUT()
        let privacySuiteSection = sut.sections[.privacySuite]
        let transferItAppRowData = privacySuiteSection?[2]
        #expect(transferItAppRowData?.title == Strings.Localizable.AccountMenu.TransferIt.buttonTitle)
        #expect(transferItAppRowData?.subtitle == Strings.Localizable.AccountMenu.TransferIt.buttonSubtitle)
        #expect(transferItAppRowData?.rowType == .externalLink)
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

    private func makeSUT(
        accountUseCase: some AccountUseCaseProtocol =  MockAccountUseCase(
            currentAccountDetails: MockMEGAAccountDetails(type: .free).toAccountDetailsEntity(),
            email: "test@test.com",
            rubbishBinStorage: 0
        )
    ) -> AccountMenuViewModel {
        let currentUserSource = CurrentUserSource(sdk: MockSdk())
        return AccountMenuViewModel(
            currentUserSource: currentUserSource,
            accountUseCase: accountUseCase,
            userImageUseCase: MockUserImageUseCase(),
            megaHandleUseCase: MockMEGAHandleUseCase(),
            fullNameHandler: { _ in "" },
            avatarFetchHandler: { _, _ in UIImage() }
        )
    }
}
