import MEGADomain
import MEGADomainMock
import MEGASdk
import MEGASDKRepo
import MEGASDKRepoMock
import MEGATest
import XCTest

final class RemoteFeatureFlagRepositoryTests: XCTestCase {
    func testRemoteFlag_callSDK() async {
        let sdk = MockSdk(remoteFeatureFlagValues: [RemoteFeatureFlag.chatMonetisation.rawValue: 1])
        let repo = RemoteFeatureFlagRepository(sdk: sdk)
        let value = await repo.remoteFeatureFlagValue(for: .chatMonetisation)
        XCTAssertEqual(value, 1)
    }
}
