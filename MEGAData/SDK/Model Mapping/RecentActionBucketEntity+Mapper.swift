
extension RecentActionBucketEntity {
    init(with recentActionBucket: MEGARecentActionBucket) {
        self.date = recentActionBucket.timestamp
        self.userEmail = recentActionBucket.userEmail
        self.parentHandle = recentActionBucket.parentHandle
        self.isUpdate = recentActionBucket.isUpdate
        self.isMedia = recentActionBucket.isMedia
        self.nodes = recentActionBucket.nodesList.toNodeEntities()
    }
}
