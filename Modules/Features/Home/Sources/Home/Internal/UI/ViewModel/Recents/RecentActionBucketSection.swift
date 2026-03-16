struct RecentActionBucketSection: Identifiable {
    var id: String { title }
    let title: String
    let buckets: [RecentActionBucketEntity]
}
