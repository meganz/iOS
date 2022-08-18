import MEGADomain

extension RecentActionBucketEntity {
    init(with recentActionBucket: MEGARecentActionBucket) {
        self.init(date: recentActionBucket.timestamp, userEmail: recentActionBucket.userEmail, parentHandle: recentActionBucket.parentHandle, isUpdate: recentActionBucket.isUpdate, isMedia: recentActionBucket.isMedia, nodes: recentActionBucket.nodesList.toNodeEntities())
    }
}
