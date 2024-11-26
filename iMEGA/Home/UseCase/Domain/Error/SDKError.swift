import Foundation

enum MEGASDKErrorType: Error {

    case ok

    /// internal error
    case internalError(_ description: String)

    /// bad arguments
    case badArguments(_ description: String)

    /// request failed, retry with exponential backoff
    case tryAgain(_ description: String)

    /// too many requests, slow down
    case tooManyRequest(_ description: String)

    /// request failed permanently
    case failedPermanently(_ description: String)

    /// too many requests for this resource
    case tooManyRequestForResource(_ description: String, MEGAUserError?, MEGALinkError?)

    /// resource access out of rage
    case outOfRange(_ description: String)

    /// resource expired
    case resourceExpired(_ description: String)

    /// resource does not exist
    case resourceNotExists(_ description: String, MEGAUserError?, MEGALinkError?)

    /// circular linkage
    case circularLink(_ description: String)

    /// access denied
    case accessDenied(_ description: String)

    /// resource already exists
    case resourceAlreadyExist(_ description: String)

    /// request incomplete
    case incompleteRequest(_ description: String)

    /// cryptographic error
    case cryptographicError(_ description: String)

    /// bad session ID
    case badSessionID(_ description: String)

    /// resource administratively blocked
    case resourceAdministrativelyBlocked(_ description: String)

    /// quote exceeded
    case quoteExceeded(_ description: String, _ availableUntil: Int64)

    /// resource temporarily not available
    case resourceTemporarilyUnavailable(_ description: String)

    /// too many connections on this resource
    case tooManyConnections(_ description: String)

    /// file could not be written to
    case canNotWrite(_ description: String)

    /// file could not be read from
    case canNotRead(_ description: String)

    /// invalid or missing application key
    case invalidApplicationKey(_ description: String)

    /// invalid SSL key
    case invalidSSLKey(_ description: String)

    /// Not enough quota
    case notEnoughQuota(_ description: String)

    /// A strongly-grouped request was rolled back
    case rolledBack(_ description: String)

    /// Multi-factor authentication required
    case multiFactorAuthenticationRequired(_ description: String)

    /// Access denied for sub-users (only for business accounts)
    case businessAccountAccessOnly(_ description: String)

    /// Business account expired
    case businessAccountExpired(_ description: String)

    /// Over Disk Quota Paywall
    case overDiskQuotaPaywall(_ description: String)

    /// An unknown & unexpected error
    case unexpected

    // MARK: -

    var isSuccess: Bool {
        if case .ok = self { return true }
        return false
    }

    func map<A>(_ f: (Self) -> A) -> A {
        return f(self)
    }
}

enum MEGAUserError: Int {
    case ETDUnknown     = -1                                           // Unknown state
    case ETDSuspension  = 7                                            // Account suspend by an ETD/ToS 'severe'
}

enum MEGALinkError: Int {
    case unknown = -1                                                  // Unknown state
    case undeleted = 0                                                 // Link is undeleted
    case undeletedDown = 1                                             // Link is deleted or down
    case downETD = 2                                                   // Link is down due to an ETD specifically
}

func transform(error: MEGAError) -> MEGASDKErrorType {
    switch error.type {
    case .apiOk:                    return .ok
    case .apiEInternal:             return .internalError(error.name)
    case .apiEArgs:                 return .badArguments(error.name)
    case .apiEAgain:                return .tryAgain(error.name)
    case .apiERateLimit:            return .tooManyRequest(error.name)
    case .apiEFailed:               return .failedPermanently(error.name)
    case .apiETooMany:              return .tooManyRequestForResource(error.name,
                                                                      transformExtraUserError(for: error),
                                                                      transformExtraLinkError(for: error))
    case .apiERange:                return .outOfRange(error.name)
    case .apiEExpired:              return .resourceExpired(error.name)
    case .apiENoent:                return .resourceNotExists(error.name,
                                                              transformExtraUserError(for: error),
                                                              transformExtraLinkError(for: error))
    case .apiECircular:             return .circularLink(error.name)
    case .apiEAccess:               return .accessDenied(error.name)
    case .apiEExist:                return .resourceAlreadyExist(error.name)
    case .apiEIncomplete:           return .incompleteRequest(error.name)
    case .apiEKey:                  return .cryptographicError(error.name)
    case .apiESid:                  return .badSessionID(error.name)
    case .apiEBlocked:              return .resourceAdministrativelyBlocked(error.name)
    case .apiEOverQuota:            return .quoteExceeded(error.name, error.value)
    case .apiETempUnavail:          return .resourceTemporarilyUnavailable(error.name)
    case .apiETooManyConnections:   return .tooManyConnections(error.name)
    case .apiEWrite:                return .canNotWrite(error.name)
    case .apiERead:                 return .canNotRead(error.name)
    case .apiEAppKey:               return .invalidApplicationKey(error.name)
    case .apiESSL:                  return .invalidSSLKey(error.name)
    case .apiEgoingOverquota:       return .notEnoughQuota(error.name)
    case .apiERolledBack:           return .rolledBack(error.name)
    case .apiEMFARequired:          return .multiFactorAuthenticationRequired(error.name)
    case .apiEMasterOnly:           return .businessAccountAccessOnly(error.name)
    case .apiEBusinessPastDue:      return .businessAccountExpired(error.name)
    case .apiEPaywall:              return .overDiskQuotaPaywall(error.name)

    @unknown default:
        assertionFailure("There is a unsupported error \(error.type)")
        return .unexpected
    }
}

private func transformExtraUserError(for error: MEGAError) -> MEGAUserError? {
    guard error.hasExtraInfo else { return nil }
    return MEGAUserError(rawValue: error.userStatus.rawValue)
}

private func transformExtraLinkError(for error: MEGAError) -> MEGALinkError? {
    guard error.hasExtraInfo else { return nil }
    return MEGALinkError(rawValue: error.linkStatus.rawValue)
}

extension MEGAError {

    var sdkError: MEGASDKErrorType? {
        if case .apiOk = type {
            return nil
        }
        return transform(error: self)
    }
}
