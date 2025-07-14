import MEGASDKRepo

public typealias RemoteFeatureFlagRepository = MEGASDKRepo.RemoteFeatureFlagRepository

extension RemoteFeatureFlagRepository {
    public static var newRepo: RemoteFeatureFlagRepository {
        MEGASDKRepo.DependencyInjection.remoteFeatureFlagRepository
    }
}
