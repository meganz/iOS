import MEGAInfrastructure

public typealias RemoteFeatureFlagRepository = MEGAInfrastructure.RemoteFeatureFlagRepository

extension RemoteFeatureFlagRepository {
    public static var newRepo: RemoteFeatureFlagRepository {
        MEGAInfrastructure.DependencyInjection.remoteFeatureFlagRepositoryImpl
    }
}
