import MEGAAppSDKRepo
import MEGADomain

public struct MockAppUpdateChecker: AppUpdateCheckerProtocol {
    private let result: Result<AppDistributionReleaseEntity?, any Error>
    
    public init(result: Result<AppDistributionReleaseEntity?, any Error>) {
        self.result = result
    }
    
    public func checkForUpdate() async throws -> AppDistributionReleaseEntity? {
        try result.get()
    }
}
