import Foundation
import MEGADomain

public extension ChatMessageEntity {
    init(status: ChatMessageStatusEntity? = nil,
         messageId: ChatIdEntity = .invalid,
         temporalId: HandleEntity = .invalid,
         messageIndex: Int = 0,
         userHandle: HandleEntity = .invalid,
         type: ChatMessageTypeEntity = .unknown,
         hasConfirmedReactions: Bool = false,
         timestamp: Date? = nil,
         content: String? = nil,
         edited: Bool = false,
         deleted: Bool = false,
         editable: Bool = false,
         deletable: Bool = false,
         managementMessage: Bool = false,
         userHandleOfAction: HandleEntity = .invalid,
         privilege: Int = 0,
         changes: ChangeType? = nil,
         code: Reason? = nil,
         usersCount: UInt = 0,
         nodes: [NodeEntity]? = nil,
         handles: [HandleEntity]? = nil,
         duration: Int = 0,
         retentionTime: UInt = 0,
         termCode: ChatMessageEndCallReasonEntity? = nil,
         rowId: HandleEntity = .invalid,
         containsMeta: ChatContainsMetaEntity? = nil,
         peers: [Peer] = [],
         isTesting: Bool = true
    ) {
        self.init(status: status, messageId: messageId, temporalId: temporalId, messageIndex: messageIndex, userHandle: userHandle, type: type, hasConfirmedReactions: hasConfirmedReactions, timestamp: timestamp, content: content, edited: edited, deleted: deleted, editable: editable, deletable: deletable, managementMessage: managementMessage, userHandleOfAction: userHandleOfAction, privilege: privilege, changes: changes, code: code, usersCount: usersCount, nodes: nodes, handles: handles, duration: duration, retentionTime: retentionTime, termCode: termCode, rowId: rowId, containsMeta: containsMeta, peers: peers)
    }
}
