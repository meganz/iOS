import XCTest
@testable import MEGA

final class AppFirstLaunchSecurityCheckerTests: XCTestCase {
    func testAppFirstLaunch() {
        let appFirstLaunchUseCase = MockAppFirstLaunchUseCase()
        XCTAssertTrue(appFirstLaunchUseCase.isFirstLaunch)
        
        let accountCleanerUseCase = MockAccountCleanerUseCase()
        XCTAssertFalse(accountCleanerUseCase.isAppGroupContainerCleaned)
        XCTAssertFalse(accountCleanerUseCase.isCredentialSessionsCleaned)
        
        let sut = AppFirstLaunchSecurityChecker(appFirstLaunchUseCase: appFirstLaunchUseCase,
                                                accountCleanerUseCase: accountCleanerUseCase)
        sut.performSecurityCheck()
        XCTAssertFalse(appFirstLaunchUseCase.isFirstLaunch)
        XCTAssertFalse(accountCleanerUseCase.isAppGroupContainerCleaned)
        XCTAssertTrue(accountCleanerUseCase.isCredentialSessionsCleaned)
    }
    
    func testAppNotFirstLaunch() {
        let appFirstLaunchUseCase = MockAppFirstLaunchUseCase()
        appFirstLaunchUseCase.markAppAsLaunched()
        XCTAssertFalse(appFirstLaunchUseCase.isFirstLaunch)
        
        let accountCleanerUseCase = MockAccountCleanerUseCase()
        XCTAssertFalse(accountCleanerUseCase.isAppGroupContainerCleaned)
        XCTAssertFalse(accountCleanerUseCase.isCredentialSessionsCleaned)
        
        let sut = AppFirstLaunchSecurityChecker(appFirstLaunchUseCase: appFirstLaunchUseCase,
                                                accountCleanerUseCase: accountCleanerUseCase)
        sut.performSecurityCheck()
        XCTAssertFalse(appFirstLaunchUseCase.isFirstLaunch)
        XCTAssertFalse(accountCleanerUseCase.isAppGroupContainerCleaned)
        XCTAssertFalse(accountCleanerUseCase.isCredentialSessionsCleaned)
    }
}
