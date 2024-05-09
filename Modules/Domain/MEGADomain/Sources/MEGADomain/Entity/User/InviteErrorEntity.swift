public enum InviteErrorEntity: Error, Equatable {
    case generic(String)
    case ownEmailEntered
    case alreadyAContact
    case isInOutgoingContactRequest
}
