public protocol AppDistributionRepositoryProtocol: RepositoryProtocol {
    func checkForUpdate() async throws -> AppDistributionReleaseEntity?
}
