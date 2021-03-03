import Foundation

struct RecentNodesRepository: RecentNodesRepositoryProtocol {
    
    private let sdk: MEGASdk

    init(sdk: MEGASdk) {
        self.sdk = sdk
    }
    
    func recentActionBuckets(completion: @escaping (Result<[RecentActionBucketEntity], QuickAccessWidgetErrorEntity>) -> Void) {
        guard let recentActionBuckets = sdk.recentActions() as? [MEGARecentActionBucket] else {
            completion(.failure(.sdk))
            return
        }
        
        let recentActionBucketEntityArray = recentActionBuckets.compactMap {
            RecentActionBucketEntity(with: $0)
        }
        
        completion(.success(recentActionBucketEntityArray))
    }

}
