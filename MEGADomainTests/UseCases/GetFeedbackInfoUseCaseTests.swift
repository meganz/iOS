import XCTest
@testable import MEGA

final class GetFeedbackInfoUseCaseTests: XCTestCase {

    func test_getFeedback() {
        let repo  = MockFeedbackInfoRepository()
        let sut = GetFeedbackInfoUseCase(repo: repo)
        
        XCTAssertNotNil(sut.getFeedback())
    }
}
