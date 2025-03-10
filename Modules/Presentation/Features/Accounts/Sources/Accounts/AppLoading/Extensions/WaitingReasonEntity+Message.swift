import MEGADomain
import MEGAL10n

extension WaitingReasonEntity {
    var message: String {
        switch self {
        case .connectivity:
            Strings.Localizable.unableToReachMega
        case .serverBusy:
            Strings.Localizable.serversAreTooBusy
        case .apiLock:
            Strings.Localizable.takingLongerThanExpected
        case .rateLimit:
            Strings.Localizable.tooManyRequest
        default:
            ""
        }
    }
}
