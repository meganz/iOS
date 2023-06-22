import MEGADomain
import MEGADomainMock
import XCTest

final class CheckSMSUseCaseTests: XCTestCase {
    func testCheckState() {
        for state in SMSStateEntity.allCases {
            let sut = CheckSMSUseCase(repo: MockSMSRepository(smsState: state))
            XCTAssertEqual(sut.checkState(), state)
        }
    }
}
