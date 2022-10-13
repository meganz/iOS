import MEGADomain

extension MEGAChatMessage {
    func toChatMessageEntity() -> ChatMessageEntity {
        ChatMessageEntity(
            status: status.toChatMessageStatusEntity(),
            messageId: messageId,
            temporalId: temporalId,
            messageIndex: messageIndex,
            userHandle: userHandle,
            type: type.toChatMessageTypeEntity(),
            hasConfirmedReactions: hasConfirmedReactions,
            timestamp: timestamp,
            content: content,
            edited: isEdited,
            deleted: isDeleted,
            editable: isEditable,
            deletable: isDeletable,
            managementMessage: isManagementMessage,
            userHandleOfAction: userHandleOfAction,
            privilege: privilege,
            changes: changes.toChangeType(),
            code: code.toReason(),
            usersCount: usersCount,
            nodes: nodeList?.toNodeEntities(),
            handles: handleList?.toHandleEntityArray(),
            duration: duration,
            retentionTime: retentionTime,
            termCode: termCode.toEndCallReason(),
            rowId: rowId,
            containsMeta: containsMeta?.toChatContainsMetaEntity()
        )
    }
}

extension MEGAChatMessageChangeType {
    func toChangeType() -> ChatMessageEntity.ChangeType? {
        switch self {
        case .status:
            return .status
        case .content:
            return .content
        case .access:
            return .access
        @unknown default:
            return nil
        }
    }
}

extension MEGAChatMessageReason {
    func toReason() -> ChatMessageEntity.Reason? {
        switch self {
        case .peersChanged:
            return .peersChanged
        case .tooOld:
            return .tooOld
        case .generalReject:
            return .generalReject
        case .noWriteAccess:
            return .noWriteAccess
        case .noChanges:
            return .noChanges
        @unknown default:
            return nil
        }
    }
}

extension MEGAChatMessageEndCallReason {
    func toEndCallReason() -> ChatMessageEndCallReasonEntity? {
        switch self {
        case .ended:
            return .ended
        case .rejected:
            return .rejected
        case .noAnswer:
            return .noAnswer
        case .failed:
            return .failed
        case .cancelled:
            return .cancelled
        case .byModerator:
            return .byModerator
        @unknown default:
            return nil
        }
    }
}





