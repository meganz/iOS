import XCTest
import MEGADomain
import MEGADomainMock

final class MEGAHandleUseCaseTests: XCTestCase {
    
    func testBase64Handle_shouldMatchBase64Handles() {
        let expectedBase64Handle = "100"
        let repo = MockMEGAHandleRepository(base64Handle: expectedBase64Handle)
        let sut = MEGAHandleUseCase(repo: repo)
        
        let base64Handle = sut.base64Handle(forUserHandle: 100)
        XCTAssertEqual(base64Handle, expectedBase64Handle)
    }
    
}
