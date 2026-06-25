public struct LastPurgeEventEntity: Sendable, Equatable {
    public let purgeTimestamp: Int64
    public let reason: PurgeReason
    public let lastActiveTimestamp: Int64

    public enum PurgeReason: Sendable {
        // There are more reasons defined in SDK, but we won't add them all here and will only add them later when it comes to
        // features that really need them
        case unknown
        case inactive
    }

    public var isInactivity: Bool { reason == .inactive }

    public init(
        purgeTimestamp: Int64,
        reason: PurgeReason,
        lastActiveTimestamp: Int64
    ) {
        self.purgeTimestamp = purgeTimestamp
        self.reason = reason
        self.lastActiveTimestamp = lastActiveTimestamp
    }
}
