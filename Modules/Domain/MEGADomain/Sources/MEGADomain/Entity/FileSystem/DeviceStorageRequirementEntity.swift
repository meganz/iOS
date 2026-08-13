/// What a set of nodes needs from the device against what the device currently has free.
public struct DeviceStorageRequirementEntity: Sendable, Equatable {
    public let requiredBytes: UInt64
    public let availableBytes: UInt64

    public init(requiredBytes: UInt64, availableBytes: UInt64) {
        self.requiredBytes = requiredBytes
        self.availableBytes = availableBytes
    }

    public var isSatisfied: Bool {
        availableBytes >= requiredBytes
    }
}

public enum DeviceStorageErrorEntity: Error, Sendable {
    /// The volume refused to report its available capacity, so the requirement cannot be judged.
    case availableCapacityUnknown
}
