import FileLink
import MEGADomain

final class MockFileLinkFlowUseCase: FileLinkFlowUseCaseProtocol, @unchecked Sendable {
    /// Runs just before the stubbed result is returned, so a test can act while the flow is in flight.
    var whileInFlight: (@MainActor @Sendable () -> Void)?

    private let initialStartResult: Result<NodeEntity, FileLinkFlowErrorEntity>
    private let confirmDecryptionKeyResult: Result<NodeEntity, FileLinkFlowErrorEntity>

    private(set) var confirmDecryptionKeyCalledArguments: [(link: String, decryptionKey: String)] = []

    init(
        initialStartResult: Result<NodeEntity, FileLinkFlowErrorEntity> = .success(NodeEntity(handle: 1)),
        confirmDecryptionKeyResult: Result<NodeEntity, FileLinkFlowErrorEntity> = .success(NodeEntity(handle: 1))
    ) {
        self.initialStartResult = initialStartResult
        self.confirmDecryptionKeyResult = confirmDecryptionKeyResult
    }

    func initialStart(with link: String) async throws(FileLinkFlowErrorEntity) -> NodeEntity {
        await whileInFlight?()
        return try initialStartResult.get()
    }

    func confirmDecryptionKey(with link: String, decryptionKey: String) async throws(FileLinkFlowErrorEntity) -> NodeEntity {
        confirmDecryptionKeyCalledArguments.append((link, decryptionKey))
        await whileInFlight?()
        return try confirmDecryptionKeyResult.get()
    }
}
