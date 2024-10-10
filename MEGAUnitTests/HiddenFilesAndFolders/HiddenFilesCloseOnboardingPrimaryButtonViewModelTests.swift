@testable import MEGA
import MEGAL10n
import MEGAPresentation
import MEGAPresentationMock
import XCTest

final class HiddenFilesCloseOnboardingPrimaryButtonViewModelTests: XCTestCase {

    func testButtonTitle_init_isCorrect() throws {
        let sut = makeSUT()
        
        XCTAssertEqual(sut.buttonTitle, Strings.Localizable.close)
    }

    @MainActor
    func testButtonAction_triggered_shouldCallDismissOnRouter() async throws {
        let router = MockHideFilesAndFoldersRouter()
        let sut = makeSUT(
            hideFilesAndFoldersRouter: router
        )
        
        await sut.buttonAction()
        
        XCTAssertEqual(router.dismissCalled, 1)
    }

    private func makeSUT(
        hideFilesAndFoldersRouter: some HideFilesAndFoldersRouting = MockHideFilesAndFoldersRouter()
    ) -> HiddenFilesCloseOnboardingPrimaryButtonViewModel {
        HiddenFilesCloseOnboardingPrimaryButtonViewModel(
            hideFilesAndFoldersRouter: hideFilesAndFoldersRouter
        )
    }
}
