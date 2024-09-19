import Foundation

public struct RecentActionBucketEntity: Sendable {
    
    public let date: Date
    public let userEmail: String?
    public let parentHandle: HandleEntity
    public let isUpdate: Bool
    public let isMedia: Bool
    public let nodes: [NodeEntity]
    
    public init(date: Date, userEmail: String? = nil, parentHandle: HandleEntity, isUpdate: Bool, isMedia: Bool, nodes: [NodeEntity]) {
        self.date = date
        self.userEmail = userEmail
        self.parentHandle = parentHandle
        self.isUpdate = isUpdate
        self.isMedia = isMedia
        self.nodes = nodes
    }
}
