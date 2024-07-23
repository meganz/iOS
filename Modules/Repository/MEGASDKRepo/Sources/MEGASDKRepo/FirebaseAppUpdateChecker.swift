@preconcurrency import FirebaseAppDistribution
import MEGADomain

public struct FirebaseAppUpdateChecker: AppUpdateCheckerProtocol {
    
    public init() {}
   
    @MainActor
    public func checkForUpdate() async throws -> AppDistributionReleaseEntity? {
        guard let release = try await AppDistribution.appDistribution().checkForUpdate() else {
            return nil
        }
        return AppDistributionReleaseEntity(
            displayVersion: release.displayVersion,
            buildVersion: release.buildVersion,
            downloadURL: release.downloadURL
        )
    }
}
