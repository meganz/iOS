public protocol RecentNodesRepositoryProtocol {
    func getAllRecentActionBuckets(completion: @escaping (Result<[RecentActionBucketEntity], GetFavouriteNodesErrorEntity>) -> Void)
    func getRecentActionBuckets(limitCount: Int, completion: @escaping (Result<[RecentActionBucketEntity], GetFavouriteNodesErrorEntity>) -> Void)
}
