@testable import MEGA
import MEGATest
import SwiftUI
import XCTest

@MainActor
final class QASettingsRouterTests: XCTestCase {
    
    func testBuild_rendersCorrectViewController() {
        let (sut, _) = makeSUT()
        
        let resultViewController = sut.build()
        
        XCTAssert(resultViewController is UIHostingController<QASettingsView>)
    }
    
    func testStart_pushCorrectViewController() {
        let (sut, mockPresenter) = makeSUT()
        
        sut.start()
        
        XCTAssertTrue(mockPresenter.viewControllers.first! is UIHostingController<QASettingsView>)
    }
    
    func testShowAlert_withTitleMessageActions_showsAlertOnPresenter() {
        let expectedTitle = anyString()
        let expectedMessage = anyString()
        let expectedActions = [UIAlertAction]()
        let (sut, mockPresenter) = makeSUT()
        
        sut.showAlert(withTitle: expectedTitle, message: expectedMessage, actions: expectedActions)
        
        let alertController = alertController(on: mockPresenter)
        XCTAssertEqual(alertController?.title, expectedTitle)
        XCTAssertEqual(alertController?.message, expectedMessage)
        XCTAssertEqual(alertController?.actions, expectedActions)
    }
    
    func testShowAlert_withError_showsAlertOnPresenter() {
        let expectedError = NSError(domain: "some-error-domain", code: 1)
        let (sut, mockPresenter) = makeSUT()
        
        sut.showAlert(withError: expectedError)
        
        let alertController = alertController(on: mockPresenter)
        XCTAssertNotNil(alertController?.title)
        XCTAssertEqual(alertController?.message, expectedError.localizedDescription)
        XCTAssertNotNil(alertController?.actions.first?.title)
        XCTAssertEqual(alertController?.actions.first?.style, .cancel)
    }
    
    // MARK: - Helpers
    
    private func makeSUT() -> (sut: QASettingsRouter, mockPresenter: MockNavigationController) {
        let mockPresenter = MockNavigationController()
        let sut = QASettingsRouter(presenter: mockPresenter)
        return (sut, mockPresenter)
    }
    
    private func alertController(on presenter: MockNavigationController, file: StaticString = #filePath, line: UInt = #line) -> UIAlertController? {
        switch presenter.messages.first {
        case let .present(viewController):
            guard let alertController = viewController as? UIAlertController else {
                XCTFail("Expect to get \(type(of: UIAlertController.self)) instance, but got \(viewController) instance instead.", file: file, line: line)
                return nil
            }
            return alertController
        case .none:
            XCTFail("Expect to present a ViewController, got nil instead.", file: file, line: line)
        }
        return nil
    }
    
    private func anyString() -> String {
        "any-string"
    }
}
