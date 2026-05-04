public protocol TransfersSettingsUseCaseProtocol: Sendable {
    /// Returns the persisted maximum number of parallel download connections from the SDK.
    func maxDownloadConnections() async throws -> Int

    /// Returns the persisted maximum number of parallel upload connections from the SDK.
    func maxUploadConnections() async throws -> Int

    /// Sets the maximum number of parallel download connections in the SDK.
    ///
    /// - Parameter connections: The number of parallel download connections (default: 4, max on mobile: 8).
    func setMaxDownloadConnections(_ connections: Int) async throws

    /// Sets the maximum number of parallel upload connections in the SDK.
    ///
    /// - Parameter connections: The number of parallel upload connections (default: 3, max on mobile: 8).
    func setMaxUploadConnections(_ connections: Int) async throws
}

public struct TransfersSettingsUseCase: TransfersSettingsUseCaseProtocol {
    private let repository: any TransfersSettingsRepositoryProtocol

    public init(repository: some TransfersSettingsRepositoryProtocol) {
        self.repository = repository
    }

    public func maxDownloadConnections() async throws -> Int {
        try await repository.maxConnections(for: .download)
    }

    public func maxUploadConnections() async throws -> Int {
        try await repository.maxConnections(for: .upload)
    }

    public func setMaxDownloadConnections(_ connections: Int) async throws {
        try await repository.setMaxConnections(connections, for: .download)
    }

    public func setMaxUploadConnections(_ connections: Int) async throws {
        try await repository.setMaxConnections(connections, for: .upload)
    }
}
