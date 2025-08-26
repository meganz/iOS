@testable import MEGA
import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGAAppPresentationMock
import MEGAL10n
import XCTest

final class HiddenFilesSeeUpgradePlansOnboardingButtonViewModelTests: XCTestCase {

    func testButtonTitle_init_isCorrect() throws {
        let sut = makeSUT()
        
        XCTAssertEqual(sut.buttonTitle, Strings.Localizable.seePlans)
    }
    
    @MainActor
    func testButtonAction_init_dismissViewAndRouteToAccountOnDismissCompletion() async {
        let hideFilesAndFoldersRouter = MockHideFilesAndFoldersRouter()
        let upgradeSubscriptionRouter = MockUpgradeSubscriptionRouter()
        let tracker = MockTracker()
        let sut = makeSUT(
            hideFilesAndFoldersRouter: hideFilesAndFoldersRouter,
            upgradeSubscriptionRouter: upgradeSubscriptionRouter,
            tracker: tracker
        )
        
        await sut.buttonAction()
        
        XCTAssertEqual(hideFilesAndFoldersRouter.dismissCalled, 1)
        hideFilesAndFoldersRouter.dismissCompletion?()
        XCTAssertEqual(upgradeSubscriptionRouter.upgradeCalled, 1)
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [HiddenNodeUpgradeUpgradeButtonPressedEvent()]
        )
    }
    
    private func makeSUT(
        hideFilesAndFoldersRouter: some HideFilesAndFoldersRouting = MockHideFilesAndFoldersRouter(),
        upgradeSubscriptionRouter: some UpgradeSubscriptionRouting = MockUpgradeSubscriptionRouter(),
        tracker: some AnalyticsTracking = MockTracker()
    ) -> HiddenFilesSeeUpgradePlansOnboardingButtonViewModel {
        HiddenFilesSeeUpgradePlansOnboardingButtonViewModel(
            hideFilesAndFoldersRouter: hideFilesAndFoldersRouter,
            upgradeSubscriptionRouter: upgradeSubscriptionRouter,
            tracker: tracker
        )
    }
}
