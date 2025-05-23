import MEGAInfrastructure

public typealias RemoteFeatureFlagRepositoryProtocol = MEGAInfrastructure.RemoteFeatureFlagRepositoryProtocol

public extension RemoteFeatureFlagRepositoryProtocol {
    func remoteFeatureFlagValue(for flag: RemoteFeatureFlag) -> Int {
        get(for: flag.rawValue)
    }
}
