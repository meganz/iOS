import MEGADomain
import MEGASdk

public final class RemoteFeatureFlagRepository: RemoteFeatureFlagRepositoryProtocol {
    public static var newRepo: RemoteFeatureFlagRepository {
        RemoteFeatureFlagRepository(sdk: MEGASdk.sharedSdk)
    }
    
    private let sdk: MEGASdk
    
    public init(sdk: MEGASdk) {
        self.sdk = sdk
    }
    
    public func remoteFeatureFlagValue(for flag: RemoteFeatureFlag) -> Int {
        sdk.remoteFeatureFlagValue(flag.rawValue)
    }
}
