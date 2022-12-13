import XCTest
import MEGADomain
import MEGADomainMock

final class GetFeedbackInfoUseCaseTests: XCTestCase {

    func test_getFeedback() {
        let repo  = MockFeedbackInfoRepository.newRepo
        let sut = GetFeedbackInfoUseCase(repo: repo)
        
        XCTAssertNotNil(sut.getFeedback())
    }
}
