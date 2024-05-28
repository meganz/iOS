import MEGADomain
import MEGADomainMock
import MEGASdk
import MEGASDKRepo
import MEGASDKRepoMock
import MEGATest
import XCTest

final class RemoteFeatureFlagRepositoryTests: XCTestCase {
    func testRemoteFlag_callSDK() async {
        let sdk = MockSdk()
        sdk.remoteFeatureFlagValues["name"] = 123
        let repo = RemoteFeatureFlagRepository(sdk: sdk)
        let value = await repo.remoteFeatureFlagValue(for: "name")
        XCTAssertEqual(value, 123)
    }
}
