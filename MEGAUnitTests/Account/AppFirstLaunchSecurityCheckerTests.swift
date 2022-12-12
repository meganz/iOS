import XCTest
@testable import MEGA
import MEGADomain
import MEGADomainMock

final class AppFirstLaunchSecurityCheckerTests: XCTestCase {
    func testAppFirstLaunch() {
        let appFirstLaunchUseCase = MockAppFirstLaunchUseCase()
        XCTAssertTrue(appFirstLaunchUseCase.isAppFirstLaunch())
        
        let accountCleanerUseCase = MockAccountCleanerUseCase()
        XCTAssertFalse(accountCleanerUseCase.isAppGroupContainerCleaned)
        XCTAssertFalse(accountCleanerUseCase.isCredentialSessionsCleaned)
        
        let sut = AppFirstLaunchSecurityChecker(appFirstLaunchUseCase: appFirstLaunchUseCase,
                                                accountCleanerUseCase: accountCleanerUseCase)
        sut.performSecurityCheck()
        XCTAssertFalse(appFirstLaunchUseCase.isAppFirstLaunch())
        XCTAssertFalse(accountCleanerUseCase.isAppGroupContainerCleaned)
        XCTAssertTrue(accountCleanerUseCase.isCredentialSessionsCleaned)
    }
    
    func testAppNotFirstLaunch() {
        let appFirstLaunchUseCase = MockAppFirstLaunchUseCase()
        appFirstLaunchUseCase.markAppAsLaunched()
        XCTAssertFalse(appFirstLaunchUseCase.isAppFirstLaunch())
        
        let accountCleanerUseCase = MockAccountCleanerUseCase()
        XCTAssertFalse(accountCleanerUseCase.isAppGroupContainerCleaned)
        XCTAssertFalse(accountCleanerUseCase.isCredentialSessionsCleaned)
        
        let sut = AppFirstLaunchSecurityChecker(appFirstLaunchUseCase: appFirstLaunchUseCase,
                                                accountCleanerUseCase: accountCleanerUseCase)
        sut.performSecurityCheck()
        XCTAssertFalse(appFirstLaunchUseCase.isAppFirstLaunch())
        XCTAssertFalse(accountCleanerUseCase.isAppGroupContainerCleaned)
        XCTAssertFalse(accountCleanerUseCase.isCredentialSessionsCleaned)
    }
}
