import MEGADomain

public protocol AppUpdateCheckerProtocol {
    func checkForUpdate() async throws -> AppDistributionReleaseEntity?
}
