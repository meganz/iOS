@testable import MEGA
import XCTest

@MainActor
final class CreateTextFileAlertViewModelTests: XCTestCase {
    let defaultFileName = "testFile.txt"
    
    private func makeSUT() -> (CreateTextFileAlertViewModel, MockCreateTextFileAlertViewRouter) {
        let mockRouter = MockCreateTextFileAlertViewRouter()
        let viewModel = CreateTextFileAlertViewModel(router: mockRouter)
        return (viewModel, mockRouter)
    }

    func testViewModelInitialization_whenInitialized_shouldNotBeNil() {
        let (sut, _) = makeSUT()
        XCTAssertNotNil(sut, "The view model should not be nil when initialized.")
    }

    func testDispatch_whenCreateTextFileAction_shouldCallCreateTextFileOnRouter() {
        let (sut, mockRouter) = makeSUT()

        sut.dispatch(.createTextFile(defaultFileName))

        XCTAssertTrue(mockRouter.createTextFile_calledTimes == 1, "The router's createTextFile method should be called once.")
        XCTAssertEqual(mockRouter.fileName, defaultFileName, "The file name passed to the router should be the same as the one dispatched.")
    }
}
