public enum ErrorTypeEntity: Error, CaseIterable {
    case ok

    /// internal error
    case internalError

    /// bad arguments
    case badArguments

    /// request failed, retry with exponential backoff
    case tryAgain

    /// too many requests, slow down
    case tooManyRequest

    /// request failed permanently
    case failedPermanently

    /// too many requests for this resource
    case tooManyRequestForResource

    /// resource access out of rage
    case outOfRange

    /// resource expired
    case resourceExpired

    /// resource does not exist
    case resourceNotExists

    /// circular linkage
    case circularLink

    /// access denied
    case accessDenied

    /// resource already exists
    case resourceAlreadyExist

    /// request incomplete
    case incompleteRequest

    /// cryptographic error
    case cryptographic

    /// bad session ID
    case badSessionID

    /// resource administratively blocked
    case resourceAdministrativelyBlocked

    /// quota exceeded
    case quotaExceeded

    /// resource temporarily not available
    case resourceTemporarilyUnavailable

    /// too many connections on this resource
    case tooManyConnections

    /// file could not be written to
    case canNotWrite

    /// file could not be read from
    case canNotRead

    /// invalid or missing application key
    case invalidApplicationKey

    /// invalid SSL key
    case invalidSSLKey

    /// Not enough quota
    case notEnoughQuota

    /// A strongly-grouped request was rolled back
    case rolledBack

    /// Multi-factor authentication required
    case multiFactorAuthenticationRequired

    /// Access denied for sub-users (only for business accounts)
    case businessMasterAccountAccessOnly

    /// Business account expired
    case businessAccountExpired

    /// Over Disk Quota Paywall
    case overDiskQuotaPaywall
}

public enum LinkErrorEntity: Sendable {
    case unknown
    case undeleted
    case undeletedOrDown
    case downETD
}

public enum UserErrorEntity: Sendable {
    case unknown
    case copyrightSuspension
    case etdSuspension
    case suspendedAdminFullDisable
}

public struct ErrorEntity: Error, Equatable {
    public let type: ErrorTypeEntity
    public let name: String
    public let value: Int64
    public let hasExtraInfo: Bool
    public let linkError: LinkErrorEntity
    public let userError: UserErrorEntity
    
    public init(
        type: ErrorTypeEntity,
        name: String = "",
        value: Int64 = 0,
        hasExtraInfo: Bool = false,
        linkError: LinkErrorEntity = .unknown,
        userError: UserErrorEntity = .unknown
    ) {
        self.type = type
        self.name = name
        self.value = value
        self.hasExtraInfo = hasExtraInfo
        self.linkError = linkError
        self.userError = userError
    }
}
