@testable import MEGA
import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGAAppPresentationMock
import MEGAL10n
import XCTest

final class WarningBannerViewModelTests: XCTestCase {
    @MainActor
    private func makeSUT(
        warningType: WarningBannerType,
        isShowCloseButton: Bool = false,
        router: some WarningBannerViewRouting = MockWarningViewRouter(),
        tracker: some AnalyticsTracking = MockTracker(),
        closeButtonAction: (() -> Void)? = nil,
        onHeightChange: ((CGFloat) -> Void)? = nil
    ) -> WarningBannerViewModel {
        WarningBannerViewModel(
            warningType: warningType,
            router: router,
            shouldShowCloseButton: isShowCloseButton,
            closeButtonAction: closeButtonAction,
            onHeightChange: onHeightChange,
            tracker: tracker
        )
    }
    
    private var randomNoActionWarningBannerType: WarningBannerType {
        [
            .noInternetConnection,
            .limitedPhotoAccess,
            .contactsNotVerified,
            .contactNotVerifiedSharedFolder("Test Folder"),
            .backupStatusError("Backup failed")
        ].randomElement()!
    }
    
    @MainActor
    func testWarningType_noInternetConnection_shouldReturnCorrectDescription() {
        let sut = makeSUT(warningType: .noInternetConnection)
        XCTAssertEqual(sut.warningType.description, Strings.Localizable.General.noIntenerConnection)
    }
    
    @MainActor
    func testWarningType_limitedPhotoAccess_shouldReturnCorrectDescription() {
        let sut = makeSUT(warningType: .limitedPhotoAccess)
        XCTAssertEqual(sut.warningType.description, Strings.Localizable.CameraUploads.Warning.limitedAccessToPhotoMessage)
    }
    
    @MainActor
    func testTapAction_limitedPhotoAccess_shouldCallGoToSettings() {
        let router = MockWarningViewRouter()
        let sut = makeSUT(
            warningType: .limitedPhotoAccess,
            router: router
        )
        sut.onBannerTapped()
        XCTAssertEqual(router.goToSettings_calledTimes, 1)
    }
    
    @MainActor
    func testTapAction_fullStorageOverQuota_shouldCallGoToSettings() {
        let router = MockWarningViewRouter()
        let sut = makeSUT(
            warningType: .fullStorageOverQuota,
            router: router
        )
        sut.onActionButtonTapped()
        XCTAssertEqual(router.presentUpgradeScreen_calledTimes, 1)
    }
    
    @MainActor
    func testWarningType_contactsNotVerified_shouldReturnCorrectDescription() {
        let sut = makeSUT(warningType: .contactsNotVerified)
        XCTAssertEqual(sut.warningType.description, Strings.Localizable.ShareFolder.contactsNotVerified)
    }
    
    @MainActor
    func testWarningType_contactNotVerifiedSharedFolder_shouldReturnCorrectDescription() {
        let folderName = "Test Folder"
        let sut = makeSUT(warningType: .contactNotVerifiedSharedFolder(folderName))
        XCTAssertEqual(sut.warningType.description, Strings.Localizable.SharedItems.ContactVerification.contactNotVerifiedBannerMessage(folderName))
    }
    
    @MainActor
    func testWarningType_backupStatusError_shouldReturnErrorMessage() {
        let errorMessage = "Backup failed"
        let sut = makeSUT(warningType: .backupStatusError(errorMessage))
        XCTAssertEqual(sut.warningType.description, errorMessage)
    }
    
    @MainActor
    func testWarningType_fullStorageOverQuota_shouldReturnCorrectValues() {
        let sut = makeSUT(warningType: .fullStorageOverQuota)
        
        XCTAssertEqual(sut.warningType.description, Strings.Localizable.Account.Storage.Banner.FullStorageOverQuotaBanner.description)
        XCTAssertEqual(sut.warningType.title, Strings.Localizable.Account.Storage.Banner.FullStorageOverQuotaBanner.title)
        XCTAssertEqual(sut.warningType.iconName, "fullStorageAlert")
        XCTAssertEqual(sut.warningType.actionText, Strings.Localizable.Account.Storage.Banner.FullStorageOverQuotaBanner.button)
        XCTAssertEqual(sut.warningType.severity, .critical)
    }
    
    @MainActor
    func testWarningType_almostFullStorageOverQuota_shouldReturnCorrectValues() {
        let sut = makeSUT(warningType: .almostFullStorageOverQuota)
        
        XCTAssertEqual(sut.warningType.description, Strings.Localizable.Account.Storage.Banner.AlmostFullStorageOverQuotaBanner.description)
        XCTAssertEqual(sut.warningType.title, Strings.Localizable.Account.Storage.Banner.AlmostFullStorageOverQuotaBanner.title)
        XCTAssertEqual(sut.warningType.iconName, "almostFullStorageAlert")
        XCTAssertEqual(sut.warningType.actionText, Strings.Localizable.Account.Storage.Banner.AlmostFullStorageOverQuotaBanner.button)
        XCTAssertEqual(sut.warningType.severity, .warning)
    }
    
    @MainActor
    func testOnViewAppear_whenWarningTypeIsFullStorageOverQuota_shouldTrackFullStorageOverQuotaBannerDisplayedEvent() {
        let tracker = MockTracker()
        let sut = makeSUT(warningType: .fullStorageOverQuota, tracker: tracker)
        
        sut.onViewAppear()
        
        XCTAssertTrue(
            tracker.trackedEventIdentifiers.contains(where: { $0.eventName == FullStorageOverQuotaBannerDisplayedEvent().eventName })
        )
    }
    
    @MainActor
    func testTapAction_whenWarningTypeIsFullStorageOverQuota_shouldTrackFullStorageOverQuotaBannerUpgradeButtonPressedEvent() {
        let tracker = MockTracker()
        let sut = makeSUT(warningType: .fullStorageOverQuota, tracker: tracker)
        
        sut.onActionButtonTapped()
        
        XCTAssertTrue(
            tracker.trackedEventIdentifiers.contains(where: { $0.eventName == FullStorageOverQuotaBannerUpgradeButtonPressedEvent().eventName })
        )
    }
    
    @MainActor
    func testWarningType_whenCloseButtonEnabled_shouldShowCloseButton() {
        let randomWarningType = WarningBannerType.random()
        let sut = makeSUT(
            warningType: randomWarningType,
            isShowCloseButton: true
        )
        XCTAssertTrue(sut.shouldShowCloseButton, "The close button should be visible for warning type \(randomWarningType)")
    }
    
    @MainActor
    func testCloseButtonAction_shouldCallCloseButtonAction() {
        var actionCalled = false
        let sut = makeSUT(warningType: .noInternetConnection) {
            actionCalled = true
        }
        sut.onCloseButtonTapped()
        XCTAssertTrue(actionCalled)
    }
    
    @MainActor
    func testHeightChangeCallback_shouldInvokeOnHeightChangeClosure() {
        var heightChangeCalled = false
        let sut = makeSUT(
            warningType: .noInternetConnection,
            onHeightChange: { _ in
            heightChangeCalled = true
        })
        sut.onHeightChange?(100.0)
        XCTAssertTrue(heightChangeCalled)
    }
    
    @MainActor
    func testApplyNewDesign_whenAlmostFullStorageOverQuota_shouldBeTrue() {
        let sut = makeSUT(warningType: .almostFullStorageOverQuota)
        XCTAssertTrue(sut.applyNewDesign)
    }
    
    @MainActor
    func testApplyNewDesign_whenFullStorageOverQuota_shouldBeTrue() {
        let sut = makeSUT(warningType: .fullStorageOverQuota)
        XCTAssertTrue(sut.applyNewDesign)
    }

    @MainActor
    func testApplyNewDesign_whenOtherWarningTypes_shouldBeFalse() {
        let sut = makeSUT(warningType: .noInternetConnection)
        XCTAssertFalse(sut.applyNewDesign)
    }

    @MainActor
    func testActionButtonTapped_whenWarningTypeHasNoAction_shouldNotTriggerRouterAction() {
        let router = MockWarningViewRouter()
        let sut = makeSUT(
            warningType: randomNoActionWarningBannerType,
            router: router
        )
        sut.onActionButtonTapped()
        
        XCTAssertEqual(router.presentUpgradeScreen_calledTimes, 0)
        XCTAssertEqual(router.goToSettings_calledTimes, 0)
    }

    @MainActor
    func testActionButtonTapped_whenWarningTypeHasNoAction_shouldNotTrackAnalytics() {
        let tracker = MockTracker()
        let sut = makeSUT(
            warningType: .contactsNotVerified,
            tracker: tracker
        )
        sut.onActionButtonTapped()
        
        XCTAssertTrue(tracker.trackedEventIdentifiers.isEmpty)
    }
}

private extension WarningBannerType {
    static var allCases: [WarningBannerType] {
        [
            .noInternetConnection,
            .limitedPhotoAccess,
            .contactsNotVerified,
            .contactNotVerifiedSharedFolder("Test Folder"),
            .backupStatusError("Backup failed"),
            .fullStorageOverQuota,
            .almostFullStorageOverQuota
        ]
    }
    
    static func random() -> WarningBannerType {
        allCases.randomElement()!
    }
}
