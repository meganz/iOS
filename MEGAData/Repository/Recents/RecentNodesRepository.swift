import Foundation
import MEGAData
import MEGADomain
import MEGASwift

struct RecentNodesRepository: RecentNodesRepositoryProtocol {
    static var newRepo: RecentNodesRepository {
        RecentNodesRepository(sdk: MEGASdk.shared)
    }
    
    private enum Constants {
        static let maxRecommendedDays = 30
        static let maxRecommendedNodes = 500
    }
    
    private let sdk: MEGASdk
    
    init(sdk: MEGASdk) {
        self.sdk = sdk
    }
    
    func recentActionBuckets(limitCount: Int = Constants.maxRecommendedNodes) async throws -> [RecentActionBucketEntity] {
        try await withAsyncThrowingValue(in: { completion in
            sdk.getRecentActionsAsync(sinceDays: Constants.maxRecommendedDays, maxNodes: limitCount, delegate: RequestDelegate { result in
                switch result {
                case .success(let request):
                    completion(.success(request.recentActionsBuckets.compactMap { RecentActionBucketEntity(with: $0) }))
                case .failure:
                    completion(.failure(GenericErrorEntity()))
                }
            })
        })
    }
}
            
