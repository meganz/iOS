public protocol DeviceStorageRepositoryProtocol: RepositoryProtocol, Sendable {
    /// Bytes the device can still make available for content the user expects to keep around.
    /// - Returns: The available capacity in bytes, or `nil` when the volume cannot be queried.
    func availableCapacity() -> UInt64?
}
