import MEGADomain

public protocol AppUpdateCheckerProtocol: Sendable {
    func checkForUpdate() async throws -> AppDistributionReleaseEntity?
}
