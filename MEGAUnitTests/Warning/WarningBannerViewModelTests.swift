@testable import MEGA
import MEGAL10n
import XCTest

final class WarningBannerViewModelTests: XCTestCase {
    private func makeSUT(
        warningType: WarningBannerType,
        isShowCloseButton: Bool = false,
        router: some WarningBannerViewRouting = MockWarningViewRouter()
    ) -> WarningBannerViewModel {
        WarningBannerViewModel(
            warningType: warningType,
            router: router,
            isShowCloseButton: isShowCloseButton
        )
    }
    
    func testWarningType_noInternetConnection_shouldReturnCorrectDescription() {
        let sut = makeSUT(warningType: .noInternetConnection)
        XCTAssertEqual(sut.warningType.description, Strings.Localizable.General.noIntenerConnection)
    }
    
    func testWarningType_limitedPhotoAccess_shouldReturnCorrectDescription() {
        let sut = makeSUT(warningType: .limitedPhotoAccess)
        XCTAssertEqual(sut.warningType.description, Strings.Localizable.CameraUploads.Warning.limitedAccessToPhotoMessage)
    }
    
    func testTapAction_limitedPhotoAccess_shouldCallGoToSettings() {
        let router = MockWarningViewRouter()
        let sut = makeSUT(
            warningType: .limitedPhotoAccess,
            router: router
        )
        sut.onBannerTapped()
        XCTAssertEqual(router.goToSettings_calledTimes, 1)
    }
    
    func testTapAction_fullStorageOverQuota_shouldCallGoToSettings() {
        let router = MockWarningViewRouter()
        let sut = makeSUT(
            warningType: .fullStorageOverQuota,
            router: router
        )
        sut.onActionButtonTapped()
        XCTAssertEqual(router.presentUpgradeScreen_calledTimes, 1)
    }
    
    func testWarningType_contactsNotVerified_shouldReturnCorrectDescription() {
        let sut = makeSUT(warningType: .contactsNotVerified)
        XCTAssertEqual(sut.warningType.description, Strings.Localizable.ShareFolder.contactsNotVerified)
    }
    
    func testWarningType_contactNotVerifiedSharedFolder_shouldReturnCorrectDescription() {
        let folderName = "Test Folder"
        let sut = makeSUT(warningType: .contactNotVerifiedSharedFolder(folderName))
        XCTAssertEqual(sut.warningType.description, Strings.Localizable.SharedItems.ContactVerification.contactNotVerifiedBannerMessage(folderName))
    }
    
    func testWarningType_backupStatusError_shouldReturnErrorMessage() {
        let errorMessage = "Backup failed"
        let sut = makeSUT(warningType: .backupStatusError(errorMessage))
        XCTAssertEqual(sut.warningType.description, errorMessage)
    }
    
    func testWarningType_fullStorageOverQuota_shouldReturnCorrectValues() {
        let sut = makeSUT(warningType: .fullStorageOverQuota)
        
        XCTAssertEqual(sut.warningType.description, Strings.Localizable.Account.Storage.Banner.FullStorageOverQuotaBanner.description)
        XCTAssertEqual(sut.warningType.title, Strings.Localizable.Account.Storage.Banner.FullStorageOverQuotaBanner.title)
        XCTAssertEqual(sut.warningType.iconName, "fullStorageAlert")
        XCTAssertEqual(sut.warningType.actionText, Strings.Localizable.Account.Storage.Banner.FullStorageOverQuotaBanner.button)
        XCTAssertEqual(sut.warningType.severity, .critical)
    }
    
    func testWarningType_almostFullStorageOverQuota_shouldReturnCorrectValues() {
        let sut = makeSUT(warningType: .almostFullStorageOverQuota)
        
        XCTAssertEqual(sut.warningType.description, Strings.Localizable.Account.Storage.Banner.AlmostFullStorageOverQuotaBanner.description)
        XCTAssertEqual(sut.warningType.title, Strings.Localizable.Account.Storage.Banner.AlmostFullStorageOverQuotaBanner.title)
        XCTAssertEqual(sut.warningType.iconName, "almostFullStorageAlert")
        XCTAssertEqual(sut.warningType.actionText, Strings.Localizable.Account.Storage.Banner.AlmostFullStorageOverQuotaBanner.button)
        XCTAssertEqual(sut.warningType.severity, .warning)
    }
}
