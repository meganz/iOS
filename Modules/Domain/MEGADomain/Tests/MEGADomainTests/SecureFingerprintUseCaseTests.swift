import MEGADomain
import MEGADomainMock
import XCTest

final class SecureFingerprintUseCaseTests: XCTestCase {
    
    func testSetSecureFingerprintFlag_shouldSetSecureFingerprintFlag() async {
        let (sut, repository) = makeSUT()
        
        await sut.setSecureFingerprintFlag(true)
        
        XCTAssertEqual(repository.messages, [ .setSecureFingerprintFlag(true) ])
    }
    
    func testToggleSecureFingerprintFlag_shouldToggleSecureFingerprintFlag() {
        let (sut, repository) = makeSUT()
        
        sut.toggleSecureFingerprintFlag()
        
        XCTAssertEqual(repository.messages, [ .toggleSecureFingerprintFlag ])
    }
    
    func testSecureFingerprintStatus_shouldReturnFingerprintStatus() {
        let (sut, repository) = makeSUT()
        
        let result = sut.secureFingerprintStatus()
        
        XCTAssertEqual(repository.messages, [ .secureFingerprintStatus ])
        XCTAssertEqual(result, "ENABLED")
    }
    
    // MARK: - Helpers
    
    private func makeSUT() -> (sut: SecureFingerprintUseCase<MockSecureFingerprintRepository>, repository: MockSecureFingerprintRepository) {
        let repository = MockSecureFingerprintRepository()
        let sut = SecureFingerprintUseCase(repo: repository)
        return (sut, repository)
    }
}
