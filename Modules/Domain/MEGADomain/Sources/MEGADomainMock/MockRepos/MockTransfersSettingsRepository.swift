import MEGADomain

public final class MockTransfersSettingsRepository: TransfersSettingsRepositoryProtocol {
    public static let newRepo = MockTransfersSettingsRepository()

    private let maxConnectionsResult: Result<Int, any Error>
    private let setMaxConnectionsResult: Result<Void, any Error>

    public init(
        maxConnectionsResult: Result<Int, any Error> = .success(4),
        setMaxConnectionsResult: Result<Void, any Error> = .success(())
    ) {
        self.maxConnectionsResult = maxConnectionsResult
        self.setMaxConnectionsResult = setMaxConnectionsResult
    }

    public func maxConnections(for direction: TransferDirectionEntity) async throws -> Int {
        try maxConnectionsResult.get()
    }

    public func setMaxConnections(_ connections: Int, for direction: TransferDirectionEntity) async throws {
        try setMaxConnectionsResult.get()
    }
}
