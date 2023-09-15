import MEGADomain
import MEGASdk

extension RecentActionBucketEntity {
    public init(with recentActionBucket: MEGARecentActionBucket) {
        self.init(date: recentActionBucket.timestamp ?? Date(),
                  userEmail: recentActionBucket.userEmail,
                  parentHandle: recentActionBucket.parentHandle,
                  isUpdate: recentActionBucket.isUpdate,
                  isMedia: recentActionBucket.isMedia,
                  nodes: recentActionBucket.nodesList?.toNodeEntities() ?? [])
    }
}
