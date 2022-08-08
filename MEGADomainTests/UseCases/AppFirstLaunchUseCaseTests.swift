import XCTest
@testable import MEGA
import MEGADomainMock

class AppFirstLaunchUseCaseTests: XCTestCase {
    func isAppFirstLaunch_true() {
        let sut = AppFirstLaunchUseCase(preferenceUserCase: MockPreferenceUseCase(dict: [.firstRun: ""]))
        
        XCTAssertTrue(sut.isAppFirstLaunch())
    }
    
    func isAppFirstLaunch_false() {
        let sut = AppFirstLaunchUseCase(preferenceUserCase: MockPreferenceUseCase(dict: [.firstRun: "1strun"]))
        
        XCTAssertFalse(sut.isAppFirstLaunch())
    }
    
    func testMarkAppAsFirstRun() {
        let sut = AppFirstLaunchUseCase(preferenceUserCase: MockPreferenceUseCase(dict: [.firstRun: ""]))
        sut.markAppAsLaunched()
        XCTAssertFalse(sut.isAppFirstLaunch())
    }
}
