import MEGADomain

public struct AppDistributionRepository: AppDistributionRepositoryProtocol {
    
    public static var newRepo: AppDistributionRepository {
        AppDistributionRepository(appUpdateChecker: FirebaseAppUpdateChecker())
    }
    
    private let appUpdateChecker: any AppUpdateCheckerProtocol
    
    public init(appUpdateChecker: some AppUpdateCheckerProtocol) {
        self.appUpdateChecker = appUpdateChecker
    }
    
    public func checkForUpdate() async throws -> AppDistributionReleaseEntity? {
        try? await appUpdateChecker.checkForUpdate()
    }
}
