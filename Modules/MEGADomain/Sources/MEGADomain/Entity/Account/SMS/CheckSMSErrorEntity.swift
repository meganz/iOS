
public enum CheckSMSErrorEntity: Error {
    case generic
    case reachedDailyLimit
    case alreadyVerifiedWithCurrentAccount
    case alreadyVerifiedWithAnotherAccount
    case wrongFormat
    case codeDoesNotMatch
}
