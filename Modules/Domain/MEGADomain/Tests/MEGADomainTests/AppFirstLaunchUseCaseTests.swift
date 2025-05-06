import MEGADomain
import MEGADomainMock
import MEGAPreference
import XCTest

class AppFirstLaunchUseCaseTests: XCTestCase {
    func isAppFirstLaunch_true() {
        let sut = AppFirstLaunchUseCase(preferenceUserCase: MockPreferenceUseCase(dict: [PreferenceKeyEntity.firstRun.rawValue: ""]))
        
        XCTAssertTrue(sut.isAppFirstLaunch())
    }
    
    func isAppFirstLaunch_false() {
        let sut = AppFirstLaunchUseCase(preferenceUserCase: MockPreferenceUseCase(dict: [PreferenceKeyEntity.firstRun.rawValue: "1strun"]))
        
        XCTAssertFalse(sut.isAppFirstLaunch())
    }
    
    func testMarkAppAsFirstRun() {
        let sut = AppFirstLaunchUseCase(preferenceUserCase: MockPreferenceUseCase(dict: [PreferenceKeyEntity.firstRun.rawValue: ""]))
        sut.markAppAsLaunched()
        XCTAssertFalse(sut.isAppFirstLaunch())
    }
}
