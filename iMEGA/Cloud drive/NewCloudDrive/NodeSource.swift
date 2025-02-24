import MEGADomain

typealias ParentNodeProvider = () -> NodeEntity?

enum NodeSource {
    /// we are using a closure returning an optional entity as
    /// when app is started offline, root node of the SDK is nil,
    /// but we need to have a way to attempt to re-acquire the node
    /// later when the app becomes connected
    case node(ParentNodeProvider)
    /// Can't use modern RecentActionBucketEntity as currently there's no way
    /// to create MEGARecentActionBucket from RecentActionBucketEntity [like we do with nodes]
    /// which is needed in the legacy CloudDriveViewController implementation
    /// This NodeSource mode should be used to construct a mode
    /// of showing nodes like in recent mode of legacy cloud drive, used in the Home -> multiple Recents files
    /// which shows CloudDriveVC in sectioned table view mode
    /// see useNewCloudDrive method and [FM-1691]
    case recentActionBucket(any RecentActionBucket)
    
    var isRoot: Bool {
        switch self {
        case .node(let parentNodeProvider):
            let node = parentNodeProvider()
            return node?.nodeType == .root
        case .recentActionBucket:
            return false
        }
    }
    
    var parentNode: NodeEntity? {
        switch self {
        case .node(let parentNodeProvider):
            guard let node = parentNodeProvider() else { return nil }
            return node
        default:
            return nil
        }
    }
}
