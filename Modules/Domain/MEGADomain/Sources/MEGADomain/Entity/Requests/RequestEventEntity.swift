public enum RequestEventEntity: Sendable, Equatable {
    case start(RequestEntity)
    case finish(RequestEntity)
    case update(RequestEntity)
    case temporaryError(RequestEntity, WaitingReasonEntity)
    
    public static func == (lhs: RequestEventEntity, rhs: RequestEventEntity) -> Bool {
        switch (lhs, rhs) {
        case let (.start(lhsEntity), .start(rhsEntity)): lhsEntity == rhsEntity
        case let (.finish(lhsEntity), .finish(rhsEntity)): lhsEntity == rhsEntity
        case let (.update(lhsEntity), .update(rhsEntity)): lhsEntity == rhsEntity
        case let (.temporaryError(lhsEntity, lhsReason), .temporaryError(rhsEntity, rhsReason)): lhsEntity == rhsEntity && lhsReason == rhsReason
        default: false
        }
    }
}
