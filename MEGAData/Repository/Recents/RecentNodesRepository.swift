import Foundation

struct RecentNodesRepository: RecentNodesRepositoryProtocol {
    
    private let sdk: MEGASdk

    init(sdk: MEGASdk) {
        self.sdk = sdk
    }
    
    func getAllRecentActionBuckets(completion: @escaping (Result<[RecentActionBucketEntity], GetFavouriteNodesErrorEntity>) -> Void) {
        guard let recentActionBuckets = sdk.recentActions() as? [MEGARecentActionBucket] else {
            completion(.failure(.sdk))
            return
        }
        
        completion(.success(recentActionBuckets.compactMap { RecentActionBucketEntity(with: $0) }))
    }
    
    func getRecentActionBuckets(limitCount: Int, completion: @escaping (Result<[RecentActionBucketEntity], GetFavouriteNodesErrorEntity>) -> Void) {
        guard let recentActionBuckets = sdk.recentActions(sinceDays: 30, maxNodes: limitCount) as? [MEGARecentActionBucket] else {
            completion(.failure(.sdk))
            return
        }
        
        completion(.success(recentActionBuckets.compactMap { RecentActionBucketEntity(with: $0) }))
    }
}
