public protocol TransfersSettingsRepositoryProtocol: RepositoryProtocol, Sendable {
    /// Returns the persisted maximum number of parallel connections for the given transfer direction.
    ///
    /// - Parameter direction: Whether to query downloads or uploads.
    /// - Returns: The current max connections value stored by the SDK.
    func maxConnections(for direction: TransferDirectionEntity) async throws -> Int

    /// Sets the maximum number of parallel connections for the given transfer direction.
    ///
    /// The SDK persists this value per base path and restores it on subsequent instances.
    ///
    /// - Parameters:
    ///   - connections: The number of parallel connections (1–100). Mobile clients typically cap this at 8.
    ///   - direction: Whether to apply to downloads or uploads.
    func setMaxConnections(_ connections: Int, for direction: TransferDirectionEntity) async throws
}
