import MEGADomain

struct RecentActionBucketEntity {
    let date: Date
    let userEmail: String?
    let parentHandle: HandleEntity
    let isUpdate: Bool
    let isMedia: Bool
    let nodes: [NodeEntity]
}
