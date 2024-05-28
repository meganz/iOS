public protocol RemoteFeatureFlagRepositoryProtocol: RepositoryProtocol, Sendable {
    func remoteFeatureFlagValue(for flag: RemoteFeatureFlagName) async -> Int
}
