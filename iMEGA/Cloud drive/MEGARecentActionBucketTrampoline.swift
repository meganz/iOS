import MEGADomain

// This is a abstraction layer to be able to mock and create item corresponding to
// MEGARecentActionBucket. Client code cannot create those objects, so using a think protocol layer
// that can hide some useful logic as well.
struct MEGARecentActionBucketTrampoline: RecentActionBucket {
    
    let timestamp: Date?
    private var nodeEntities: [NodeEntity]
    let isMedia: Bool
    let isUpdate: Bool
    let parentHandle: HandleEntity
    let parentNodeProvider: @Sendable () -> NodeEntity?
    
    // REMOVE WHEN REMOVING : LegacyCloudDriveViewControllerFactory
    // it's only needed for backwards compatibility
    let bucket: MEGARecentActionBucket?
    
    // this is used to signal situation when last item was remove from currently
    // rendered bucket
    static let empty = MEGARecentActionBucketTrampoline(
        bucket: nil,
        parentNodeProvider: { _ in nil }
    )
    
    init(
        bucket: MEGARecentActionBucket?,
        // adde to avoid referencing MEGA SDK
        parentNodeProvider: @escaping (HandleEntity) -> NodeEntity?
    ) {
        self.bucket = bucket
        timestamp = bucket?.timestamp ?? Date()
        nodeEntities = bucket?.nodesList?.toNodeEntities() ?? []
        isMedia = bucket?.isMedia ?? false
        isUpdate = bucket?.isUpdate ?? false
        if let bucket {
            let _parentHandle = bucket.parentHandle
            parentHandle = _parentHandle
            self.parentNodeProvider = {
                parentNodeProvider(_parentHandle)
            }
        } else {
            parentHandle = .invalid
            self.parentNodeProvider = { nil }
        }
    }
    
    func removing(_ handles: [HandleEntity]) -> MEGARecentActionBucketTrampoline {
        var copy = self
        let set = Set(handles)
        copy.nodeEntities = copy.nodeEntities.filter {
            !set.contains($0.handle)
        }
        return copy
    }
    
    func allNodes() -> [NodeEntity] {
        nodeEntities
    }
    
    func nodeAt(idx: Int) -> NodeEntity? {
        return nodeEntities[safe: idx]
    }
    
    var nodeCount: Int {
        nodeEntities.count
    }
    
    func parentNode() -> NodeEntity? {
        parentNodeProvider()
    }
}
