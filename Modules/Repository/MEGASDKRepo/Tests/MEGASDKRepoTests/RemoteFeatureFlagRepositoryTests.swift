import MEGADomain
import MEGASDKRepo
import MEGASDKRepoMock
import Testing

struct RemoteFeatureFlagRepositoryTests {
    @Suite("Call to remote feature flag value")
    struct RemoteFeatureFlagValue {
        
        @Test("When retrieving a remote feature flag value, it should call the SDK",
              arguments: [0, 1])
        func remoteFeatureFlagValue(sdkValue: Int) {
            let sdk = MockSdk(remoteFeatureFlagValues: [RemoteFeatureFlag.chatMonetisation.rawValue: sdkValue])
            let repo = RemoteFeatureFlagRepository(sdk: sdk)
            
            #expect(repo.remoteFeatureFlagValue(for: .chatMonetisation) == sdkValue)
        }
    }
}
