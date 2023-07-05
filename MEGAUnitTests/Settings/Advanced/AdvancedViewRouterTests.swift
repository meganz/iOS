@testable import MEGA
import MEGATest
import XCTest

final class AdvancedViewRouterTests: XCTestCase {
    
    func testBuild_rendersCorrectViewController() {
        let (sut, _) = makeSUT()
        
        let resultViewController = sut.build()
        
        XCTAssert(resultViewController is AdvancedTableViewController)
    }
    
    func testStart_pushCorrectViewController() {
        let (sut, mockPresenter) = makeSUT()
        
        sut.start()
        
        XCTAssertTrue(mockPresenter.viewControllers.first! is AdvancedTableViewController)
    }
    
    // MARK: - Helpers
    
    private func makeSUT() -> (sut: AdvancedViewRouter, mockPresenter: UINavigationController) {
        let mockPresenter = UINavigationController()
        let sut = AdvancedViewRouter(presenter: mockPresenter)
        return (sut, mockPresenter)
    }
}
