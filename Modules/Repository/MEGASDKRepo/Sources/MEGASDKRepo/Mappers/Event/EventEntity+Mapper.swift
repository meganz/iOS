import MEGADomain
import MEGASdk

extension EventEntity.EventType {
    public var code: Int {
        switch self {
        case .commitDB: 0
        case .accountConfirmation: 1
        case .changeToHttps: 2
        case .disconnect: 3
        case .accountBlocked: 4
        case .storage: 5
        case .nodesCurrent: 6
        case .mediaInfoReady: 7
        case .storageSumChanged: 8
        case .businessStatus: 9
        case .keyModified: 10
        case .miscFlagsReady: 11
        case .syncsDisabled: 12
        case .syncsRestored: 13
        case .reqStatProgress: 14
        case .reloading: 15
        case .fatalError: 16
        case .upgradeSecurity: 17
        case .downgradeAttack: 18
        case .confirmUserEmail: 19
        case .creditCardExpiry: 20
        }
    }
}

extension EventEntity.ReasonError {
    public var code: Int {
        switch self {
        case .unknown: -1
        case .noError: 0
        case .failureUnserializeNode: 1
        case .dbIOFailure: 2
        case .dbFull: 3
        case .dbIndexOverflow: 4
        }
    }
}

extension EventEntity.StorageState {
    public var code: Int {
        switch self {
        case .green: 0
        case .orange: 1
        case .red: 2
        case .change: 3
        case .paywall: 4
        }
    }
}

extension MEGAEvent {
    public func toEventEntity() -> EventEntity {
        EventEntity(
            type: type.toEventType(),
            text: text,
            reason: mapCodeToReasonError(from: number),
            storageState: type == .storage ? mapCodeToStorageState(from: number) : nil,
            description: eventString
        )
    }
    
    public func mapCodeToReasonError(from code: Int) -> EventEntity.ReasonError {
        switch code {
        case -1: EventEntity.ReasonError.unknown
        case 0: EventEntity.ReasonError.noError
        case 1: EventEntity.ReasonError.failureUnserializeNode
        case 2: EventEntity.ReasonError.dbIOFailure
        case 3: EventEntity.ReasonError.dbFull
        case 4: EventEntity.ReasonError.dbIndexOverflow
        default: EventEntity.ReasonError.unknown
        }
    }
    
    public func mapCodeToStorageState(from code: Int) -> EventEntity.StorageState? {
        switch code {
        case 0: EventEntity.StorageState.green
        case 1: EventEntity.StorageState.orange
        case 2: EventEntity.StorageState.red
        case 3: EventEntity.StorageState.change
        case 4: EventEntity.StorageState.paywall
        default: nil
        }
    }
}

extension Event {
    public func toEventType() -> EventEntity.EventType? {
        switch self {
        case .commitDB: EventEntity.EventType.commitDB
        case .accountConfirmation: EventEntity.EventType.accountConfirmation
        case .changeToHttps: EventEntity.EventType.changeToHttps
        case .disconnect: EventEntity.EventType.disconnect
        case .accountBlocked: EventEntity.EventType.accountBlocked
        case .storage: EventEntity.EventType.storage
        case .nodesCurrent: EventEntity.EventType.nodesCurrent
        case .mediaInfoReady: EventEntity.EventType.mediaInfoReady
        case .storageSumChanged: EventEntity.EventType.storageSumChanged
        case .businessStatus: EventEntity.EventType.businessStatus
        case .keyModified: EventEntity.EventType.keyModified
        case .miscFlagsReady: EventEntity.EventType.miscFlagsReady
#if ENABLE_SYNC
        case .syncsDisabled: EventEntity.EventType.syncsDisabled
        case .syncsRestored: EventEntity.EventType.syncsRestored
#endif
        case .reqStatProgress: EventEntity.EventType.reqStatProgress
        case .reloading: EventEntity.EventType.reloading
        case .fatalError: EventEntity.EventType.fatalError
        case .upgradeSecurity: EventEntity.EventType.upgradeSecurity
        case .downgradeAttack: EventEntity.EventType.downgradeAttack
        case .confirmUserEmail: EventEntity.EventType.confirmUserEmail
        case .creditCardExpiry: EventEntity.EventType.creditCardExpiry
        @unknown default:  nil
        }
    }
}
