@testable import MEGA
import MEGAL10n
import XCTest

final class HiddenFilesSeeUpgradePlansOnboardingButtonViewModelTests: XCTestCase {

    func testButtonTitle_init_isCorrect() throws {
        let sut = makeSUT()
        
        XCTAssertEqual(sut.buttonTitle, Strings.Localizable.seePlans)
    }
    
    func testButtonAction_init_dismissViewAndRouteToAccountOnDismissCompletion() async {
        let hideFilesAndFoldersRouter = MockHideFilesAndFoldersRouter()
        let upgradeAccountRouter = MockUpgradeAccountRouter()
        let sut = makeSUT(
            hideFilesAndFoldersRouter: hideFilesAndFoldersRouter,
            upgradeAccountRouter: upgradeAccountRouter)
        
        await sut.buttonAction()
        
        XCTAssertEqual(hideFilesAndFoldersRouter.dismissCalled, 1)
        hideFilesAndFoldersRouter.dismissCompletion?()
        XCTAssertEqual(upgradeAccountRouter.presentUpgradeTVCRecorder.callCount, 1)
    }
    
    private func makeSUT(
        hideFilesAndFoldersRouter: some HideFilesAndFoldersRouting = MockHideFilesAndFoldersRouter(),
        upgradeAccountRouter: some UpgradeAccountRouting = MockUpgradeAccountRouter()
    ) -> HiddenFilesSeeUpgradePlansOnboardingButtonViewModel {
        HiddenFilesSeeUpgradePlansOnboardingButtonViewModel(
            hideFilesAndFoldersRouter: hideFilesAndFoldersRouter,
            upgradeAccountRouter: upgradeAccountRouter
        )
    }
}
