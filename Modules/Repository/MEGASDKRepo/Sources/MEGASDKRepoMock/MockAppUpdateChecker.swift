import MEGADomain
import MEGASDKRepo

public struct MockAppUpdateChecker: AppUpdateCheckerProtocol {
    private let result: Result<AppDistributionReleaseEntity?, Error>
    
    public init(result: Result<AppDistributionReleaseEntity?, Error>) {
        self.result = result
    }
    
    public func checkForUpdate() async throws -> AppDistributionReleaseEntity? {
        try result.get()
    }
}
