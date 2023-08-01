import Foundation
import MEGADomain

public struct MockAppDistributionRepository: AppDistributionRepositoryProtocol {
    public static var newRepo: MockAppDistributionRepository {
        MockAppDistributionRepository(result: .failure(NSError()))
    }
    
    private let result: Result<AppDistributionReleaseEntity?, Error>
    
    public init(result: Result<AppDistributionReleaseEntity?, Error>) {
        self.result = result
    }
    
    public func checkForUpdate() async throws -> AppDistributionReleaseEntity? {
        try result.get()
    }
}
