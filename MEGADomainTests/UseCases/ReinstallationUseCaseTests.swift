import XCTest
@testable import MEGA

class ReinstallationUseCaseTests: XCTestCase {
    func testAppIsReinstalled() {
        let sut = ReinstallationUseCase(preferenceUserCase: MockPreferenceUseCase(dict: [.firstRun: ""]),
                                        credentialRepo: MockCredentialRepository())
        
        XCTAssertTrue(sut.isAppReinstalled())
    }
    
    func testAppIsNotReinstalled() {
        let sut = ReinstallationUseCase(preferenceUserCase: MockPreferenceUseCase(dict: [.firstRun: "1strun"]),
                                        credentialRepo: MockCredentialRepository())
        
        XCTAssertFalse(sut.isAppReinstalled())
    }
    
    func testMarkAppAsFirstRun() {
        let sut = ReinstallationUseCase(preferenceUserCase: MockPreferenceUseCase(dict: [.firstRun: ""]),
                                        credentialRepo: MockCredentialRepository())
        sut.markAppAsFirstRun()
        XCTAssertFalse(sut.isAppReinstalled())
    }
}
