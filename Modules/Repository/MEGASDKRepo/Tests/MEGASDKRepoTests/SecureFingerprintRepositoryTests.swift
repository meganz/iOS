import MEGADomain
import MEGASDKRepo
import MEGASDKRepoMock
import XCTest

final class SecureFingerprintRepositoryTests: XCTestCase {
    
    func testSetSecureFingerprintFlag_shouldSetSecureFingerprintFlag() async {
        let (sut, manager) = makeSUT()
        
        await sut.setSecureFingerprintFlag(true)
        
        XCTAssertEqual(manager.messages, [ .setSecureFingerprintFlag(true) ])
    }
    
    func testToggleSecureFingerprintFlag_shouldToggleSecureFingerprintFlag() {
        let (sut, manager) = makeSUT()
        
        sut.toggleSecureFingerprintFlag()
        
        XCTAssertEqual(manager.messages, [ .toggleSecureFingerprintFlag ])
    }
    
    func testSecureFingerprintStatus_shouldReturnFingerprintStatus() {
        let (sut, manager) = makeSUT()
        
        let result = sut.secureFingerprintStatus()
        
        XCTAssertEqual(manager.messages, [ .secureFingerprintStatus ])
        XCTAssertEqual(result, "ENABLED")
    }
    
    // MARK: - Helpers
    
    private func makeSUT() -> (sut: SecureFingerprintRepository, manager: MockSecureFingerprintManager) {
        let manager = MockSecureFingerprintManager()
        let sut = SecureFingerprintRepository(manager: manager)
        return (sut, manager)
    }
}
