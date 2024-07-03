public protocol AppDistributionRepositoryProtocol: RepositoryProtocol, Sendable {
    func checkForUpdate() async throws -> AppDistributionReleaseEntity?
}
