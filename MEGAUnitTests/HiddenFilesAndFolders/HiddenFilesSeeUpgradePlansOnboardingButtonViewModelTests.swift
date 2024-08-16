@testable import MEGA
import MEGAAnalyticsiOS
import MEGAL10n
import MEGAPresentation
import MEGAPresentationMock
import XCTest

final class HiddenFilesSeeUpgradePlansOnboardingButtonViewModelTests: XCTestCase {

    func testButtonTitle_init_isCorrect() throws {
        let sut = makeSUT()
        
        XCTAssertEqual(sut.buttonTitle, Strings.Localizable.seePlans)
    }
    
    func testButtonAction_init_dismissViewAndRouteToAccountOnDismissCompletion() async {
        let hideFilesAndFoldersRouter = MockHideFilesAndFoldersRouter()
        let upgradeAccountRouter = MockUpgradeAccountRouter()
        let tracker = MockTracker()
        let sut = makeSUT(
            hideFilesAndFoldersRouter: hideFilesAndFoldersRouter,
            upgradeAccountRouter: upgradeAccountRouter,
            tracker: tracker
        )
        
        await sut.buttonAction()
        
        XCTAssertEqual(hideFilesAndFoldersRouter.dismissCalled, 1)
        hideFilesAndFoldersRouter.dismissCompletion?()
        XCTAssertEqual(upgradeAccountRouter.presentUpgradeTVCRecorder.callCount, 1)
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [HiddenNodeUpgradeUpgradeButtonPressedEvent()]
        )
    }
    
    private func makeSUT(
        hideFilesAndFoldersRouter: some HideFilesAndFoldersRouting = MockHideFilesAndFoldersRouter(),
        upgradeAccountRouter: some UpgradeAccountRouting = MockUpgradeAccountRouter(),
        tracker: some AnalyticsTracking = MockTracker()
    ) -> HiddenFilesSeeUpgradePlansOnboardingButtonViewModel {
        HiddenFilesSeeUpgradePlansOnboardingButtonViewModel(
            hideFilesAndFoldersRouter: hideFilesAndFoldersRouter,
            upgradeAccountRouter: upgradeAccountRouter,
            tracker: tracker
        )
    }
}
