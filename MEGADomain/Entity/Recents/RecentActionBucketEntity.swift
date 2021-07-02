struct RecentActionBucketEntity {
    let date: Date
    let userEmail: String?
    let parentHandle: MEGAHandle
    let isUpdate: Bool
    let isMedia: Bool
    let nodes: [NodeEntity]
}
