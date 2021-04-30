
enum InviteError: Error {
    case generic(String)
    case ownEmailEntered
    case alreadyAContact
    case isInOutgoingContactRequest
}
