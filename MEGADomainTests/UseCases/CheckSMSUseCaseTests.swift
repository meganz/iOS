import XCTest
@testable import MEGA

final class CheckSMSUseCaseTests: XCTestCase {
    func testCheckState() {
        for state in SMSStateEntity.allCases {
            let sut = CheckSMSUseCase(repo: MockSMSRepository(smsState: state))
            XCTAssertEqual(sut.checkState(), state)
        }
    }
    
    func testSendVerification_wrongFormat() {
        let sut = CheckSMSUseCase(repo: MockSMSRepository(sendToNumberResult: .success("")))
        sut.sendVerification(toPhoneNumber: "12345") { result in
            switch result {
            case .failure(let error):
                XCTAssertEqual(error, .wrongFormat)
            case .success:
                XCTFail("Wrong format is expected!")
            }
        }
    }
}
