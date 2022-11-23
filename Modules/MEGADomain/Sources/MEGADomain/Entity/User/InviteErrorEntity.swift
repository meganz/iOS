
public enum InviteErrorEntity: Error {
    case generic(String)
    case ownEmailEntered
    case alreadyAContact
    case isInOutgoingContactRequest
}
