@testable import MEGAAppSDKRepo
import MEGADomain
import MEGASdk
import XCTest

final class MEGASDKSharedInstanceTests: XCTestCase {
    func testUserAgent_debugConfiguration_appendsDevEnvironment() {
        let agent = MEGASdk.userAgent(for: .debug)

        XCTAssertTrue(agent.contains("MEGAEnv/Dev"), agent)
        XCTAssertFalse(agent.contains("MEGAEnv/QA"), agent)
    }

    func testUserAgent_qaConfiguration_appendsQAEnvironment() {
        let agent = MEGASdk.userAgent(for: .qa)

        XCTAssertTrue(agent.contains("MEGAEnv/QA"), agent)
        XCTAssertFalse(agent.contains("MEGAEnv/Dev"), agent)
    }

    func testUserAgent_shippingConfigurations_appendNoEnvironment() {
        for configuration in [AppConfigurationEntity.production, .testFlight] {
            let agent = MEGASdk.userAgent(for: configuration)

            XCTAssertFalse(agent.contains("MEGAEnv/"), "\(configuration) produced \(agent)")
        }
    }

    func testUserAgent_everyConfiguration_carriesTheAppIdentifier() {
        for configuration in AppConfigurationEntity.allCases {
            let agent = MEGASdk.userAgent(for: configuration)

            XCTAssertTrue(agent.hasPrefix("MEGAiOS/"), "\(configuration) produced \(agent)")
        }
    }

    /// The shared instances bake their user agent in on first access, so this asserts only what holds
    /// whatever order the suite runs in. Which environment suffix each instance ended up with is
    /// covered by the configuration tests above.
    func testSharedInstances_userAgent_carriesTheAppIdentifier() {
        for sdk in [MEGASdk.sharedSdk, .sharedNSESdk, .sharedFolderLinkSdk] {
            XCTAssertEqual(sdk.userAgent?.hasPrefix("MEGAiOS/"), true, sdk.userAgent ?? "nil")
        }
    }
}
