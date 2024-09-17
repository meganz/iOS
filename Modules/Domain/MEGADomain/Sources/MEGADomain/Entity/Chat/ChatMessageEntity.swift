import Foundation

public struct ChatMessageEntity: Sendable {
    public enum ChangeType: Sendable {
        case status
        case content
        case access
    }
    
    public enum Reason: Sendable {
        case peersChanged
        case tooOld
        case generalReject
        case noWriteAccess
        case noChanges
    }
    
    public let status: ChatMessageStatusEntity?
    public let messageId: ChatIdEntity
    public let temporalId: HandleEntity
    public let messageIndex: Int
    public let userHandle: HandleEntity
    public let type: ChatMessageTypeEntity
    public let hasConfirmedReactions: Bool
    public let timestamp: Date?
    public let content: String?
    public let edited: Bool
    public let deleted: Bool
    public let editable: Bool
    public let deletable: Bool
    public let managementMessage: Bool
    public let userHandleOfAction: HandleEntity
    public let privilege: Int
    public let changes: ChangeType?
    public let code: Reason?
    public let usersCount: UInt
    public let nodes: [NodeEntity]?
    public let handles: [HandleEntity]?
    public let duration: Int
    public let retentionTime: UInt
    public let termCode: ChatMessageEndCallReasonEntity?
    public let rowId: HandleEntity
    public let containsMeta: ChatContainsMetaEntity?
    public let peers: [Peer]
    
    public struct Peer: Sendable {
        public let handle: HandleEntity
        public let name: String?
        public let email: String?
        
        public init(handle: HandleEntity, name: String?, email: String?) {
            self.handle = handle
            self.name = name
            self.email = email
        }
    }
    
    public init(status: ChatMessageStatusEntity?, messageId: ChatIdEntity, temporalId: HandleEntity, messageIndex: Int, userHandle: HandleEntity, type: ChatMessageTypeEntity, hasConfirmedReactions: Bool, timestamp: Date?, content: String?, edited: Bool, deleted: Bool, editable: Bool, deletable: Bool, managementMessage: Bool, userHandleOfAction: HandleEntity, privilege: Int, changes: ChangeType?, code: Reason?, usersCount: UInt, nodes: [NodeEntity]?, handles: [HandleEntity]?, duration: Int, retentionTime: UInt, termCode: ChatMessageEndCallReasonEntity?, rowId: HandleEntity, containsMeta: ChatContainsMetaEntity?, peers: [Peer]) {
        self.status = status
        self.messageId = messageId
        self.temporalId = temporalId
        self.messageIndex = messageIndex
        self.userHandle = userHandle
        self.type = type
        self.hasConfirmedReactions = hasConfirmedReactions
        self.timestamp = timestamp
        self.content = content
        self.edited = edited
        self.deleted = deleted
        self.editable = editable
        self.deletable = deletable
        self.managementMessage = managementMessage
        self.userHandleOfAction = userHandleOfAction
        self.privilege = privilege
        self.changes = changes
        self.code = code
        self.usersCount = usersCount
        self.nodes = nodes
        self.handles = handles
        self.duration = duration
        self.retentionTime = retentionTime
        self.termCode = termCode
        self.rowId = rowId
        self.containsMeta = containsMeta
        self.peers = peers
    }
}
