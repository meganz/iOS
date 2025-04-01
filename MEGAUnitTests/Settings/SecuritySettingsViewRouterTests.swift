@testable import MEGA
import MEGATest
import XCTest

final class SecuritySettingsViewRouterTests: XCTestCase {
    func test_build_returnsSecurityOptionsTableViewController() {
        let (sut, _) = makeSUT()

        let resultViewController = sut.build()

        XCTAssert(resultViewController is SecurityOptionsTableViewController)
    }

    func test_start_pushesSecurityOptionsTableViewController() throws {
        let (sut, mockPresenter) = makeSUT()

        sut.start()

        let pushedVC = try XCTUnwrap(
            mockPresenter.viewControllers.first,
            "no vc was pushed"
        )

        XCTAssertTrue(pushedVC is SecurityOptionsTableViewController)
    }

    private func makeSUT() -> (sut: SecuritySettingsViewRouter, mockPresenter: MockNavigationController) {
        let mockPresenter = MockNavigationController()
        let sut = SecuritySettingsViewRouter(presenter: mockPresenter)
        return (sut, mockPresenter)
    }
}
