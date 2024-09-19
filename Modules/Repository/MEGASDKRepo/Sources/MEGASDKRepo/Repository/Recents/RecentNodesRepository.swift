import Foundation
import MEGADomain
import MEGASdk
import MEGASwift

public struct RecentNodesRepository: RecentNodesRepositoryProtocol {
    public static var newRepo: RecentNodesRepository {
        RecentNodesRepository(sdk: MEGASdk.sharedSdk)
    }
    
    public enum Constants {
        public static let maxRecommendedDays = 30
        public static let maxRecommendedNodes = 500
    }
    
    private let sdk: MEGASdk
    
    public init(sdk: MEGASdk) {
        self.sdk = sdk
    }
    
    public func recentActionBuckets(limitCount: Int = Constants.maxRecommendedNodes, excludeSensitive: Bool) async throws -> [RecentActionBucketEntity] {
        try await withAsyncThrowingValue(in: { completion in
            sdk.getRecentActionsAsync(sinceDays: Constants.maxRecommendedDays, maxNodes: limitCount, excludeSensitives: excludeSensitive, delegate: RequestDelegate { result in
                switch result {
                case .success(let request):
                    completion(.success(request.recentActionsBuckets?.compactMap { RecentActionBucketEntity(with: $0) } ?? []))
                case .failure:
                    completion(.failure(GenericErrorEntity()))
                }
            })
        })
    }
}
            
