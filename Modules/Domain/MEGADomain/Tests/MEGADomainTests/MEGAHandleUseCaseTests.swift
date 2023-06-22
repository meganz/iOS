import MEGADomain
import MEGADomainMock
import XCTest

final class MEGAHandleUseCaseTests: XCTestCase {
    
    func testBase64Handle_shouldMatchBase64Handles() {
        let expectedBase64Handle = Base64HandleEntity("100")
        let repo = MockMEGAHandleRepository()
        let sut = MEGAHandleUseCase(repo: repo)
        
        let base64Handle = sut.base64Handle(forUserHandle: HandleEntity(100))
        XCTAssertEqual(base64Handle, expectedBase64Handle)
    }
    
    func testHandle_shouldMatchHandles() {
        let expectedHandle = HandleEntity(100)
        let repo = MockMEGAHandleRepository()
        let sut = MEGAHandleUseCase(repo: repo)
        
        let handle = sut.handle(forBase64Handle: Base64HandleEntity("100"))
        XCTAssertEqual(handle, expectedHandle)
    }
}
