import MEGAAppSDKRepo
import MEGADomain
import MEGASdk
import XCTest

final class MEGASDKSharedInstanceTests: XCTestCase {
    func testUserAgent_ProductionAppEnvironment_noQAOrDev() {
        let appEnv = AppEnvironmentUseCase.shared
        appEnv.config(.production)
        let userAgent = MEGASdk.sharedSdk.userAgent
        XCTAssertTrue(userAgent?.contains("MEGAEnv/QA") == false)
        XCTAssertTrue(userAgent?.contains("MEGAEnv/Dev") == false)
    }
    
    func testUserAgent_DevAppEnvironment_noQAOrDev() {
        let appEnv = AppEnvironmentUseCase.shared
        appEnv.config(.debug)
        let userAgent = MEGASdk.sharedNSESdk.userAgent
        XCTAssertTrue(userAgent?.contains("MEGAEnv/Dev") == true)
    }
    
    func testUserAgent_QAAppEnvironment_QAAgent() {
        let appEnv = AppEnvironmentUseCase.shared
        appEnv.config(.qa)
        let userAgent = MEGASdk.sharedFolderLinkSdk.userAgent
        XCTAssertTrue(userAgent?.contains("MEGAEnv/QA") == true)
    }
}
