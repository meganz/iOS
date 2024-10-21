public protocol RemoteFeatureFlagRepositoryProtocol: RepositoryProtocol, Sendable {
    func remoteFeatureFlagValue(for flag: RemoteFeatureFlag) -> Int
}
