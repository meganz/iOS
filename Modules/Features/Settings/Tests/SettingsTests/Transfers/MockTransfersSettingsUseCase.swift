import MEGADomain

final class MockTransfersSettingsUseCase: TransfersSettingsUseCaseProtocol, @unchecked Sendable {
    var maxDownloadConnectionsResult: Result<Int, Error> = .success(4)
    var maxUploadConnectionsResult: Result<Int, Error> = .success(3)
    var setMaxDownloadConnectionsResult: Result<Void, Error> = .success(())
    var setMaxUploadConnectionsResult: Result<Void, Error> = .success(())

    private(set) var setMaxDownloadConnectionsCalls: [Int] = []
    private(set) var setMaxUploadConnectionsCalls: [Int] = []

    func maxDownloadConnections() async throws -> Int {
        try maxDownloadConnectionsResult.get()
    }

    func maxUploadConnections() async throws -> Int {
        try maxUploadConnectionsResult.get()
    }

    func setMaxDownloadConnections(_ connections: Int) async throws {
        setMaxDownloadConnectionsCalls.append(connections)
        try setMaxDownloadConnectionsResult.get()
    }

    func setMaxUploadConnections(_ connections: Int) async throws {
        setMaxUploadConnectionsCalls.append(connections)
        try setMaxUploadConnectionsResult.get()
    }
}
