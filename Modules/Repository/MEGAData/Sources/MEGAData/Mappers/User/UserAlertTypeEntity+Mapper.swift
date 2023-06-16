import MEGADomain
import MEGASdk

extension MEGAUserAlertType {
    public func toUserAlertType() -> UserAlertTypeEntity {
        switch self {
        case .incomingPendingContactRequest: return .incomingPendingContactRequest
        case .incomingPendingContactCancelled: return .incomingPendingContactCancelled
        case .incomingPendingContactReminder: return .incomingPendingContactReminder
        case .contactChangeDeletedYou: return .contactChangeDeletedYou
        case .contactChangeContactEstablished: return .contactChangeContactEstablished
        case .contactChangeAccountDeleted: return .contactChangeAccountDeleted
        case .contactChangeBlockedYou: return .contactChangeBlockedYou
        case .updatePendingContactIncomingIgnored: return .updatePendingContactIncomingIgnored
        case .updatePendingContactIncomingAccepted: return .updatePendingContactIncomingAccepted
        case .updatePendingContactIncomingDenied: return .updatePendingContactIncomingDenied
        case .updatePendingContactOutgoingAccepted: return .updatePendingContactOutgoingAccepted
        case .updatePendingContactOutgoingDenied: return .updatePendingContactOutgoingDenied
        case .newShare: return .newShare
        case .deletedShare: return .deletedShare
        case .newShareNodes: return .newShareNodes
        case .removedSharesNodes: return .removedSharesNodes
        case .updatedSharedNodes: return .updatedSharedNodes
        case .paymentSucceeded: return .paymentSucceeded
        case .paymentFailed: return .paymentFailed
        case .paymentReminder: return .paymentReminder
        case .takedown: return .takedown
        case .takedownReinstated: return .takedownReinstated
        case .scheduledMeetingNew: return .scheduledMeetingNew
        case .scheduledMeetingDeleted: return .scheduledMeetingDeleted
        case .scheduledMeetingUpdated: return .scheduledMeetingUpdated
        case .total: return .total
        @unknown default: return .unknown
        }
    }
}
