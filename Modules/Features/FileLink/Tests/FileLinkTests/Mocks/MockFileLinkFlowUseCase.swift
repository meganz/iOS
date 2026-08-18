import FileLink
import MEGADomain

final class MockFileLinkFlowUseCase: FileLinkFlowUseCaseProtocol, @unchecked Sendable {
    /// Runs just before the stubbed result is returned, so a test can act while the flow is in flight.
    var whileInFlight: (@MainActor @Sendable () -> Void)?

    private let initialStartResult: Result<NodeEntity, FileLinkFlowErrorEntity>
    private let confirmDecryptionKeyResult: Result<NodeEntity, FileLinkFlowErrorEntity>
    private let resolvedLink: String?

    private(set) var confirmDecryptionKeyCalledArguments: [(link: String, decryptionKey: String)] = []

    /// - Parameter resolvedLink: the link the stubbed flow reports having resolved from. Left unset it is
    ///   the link it was asked with, which is what the real flow reports unless the user had to type a
    ///   decryption key in.
    init(
        initialStartResult: Result<NodeEntity, FileLinkFlowErrorEntity> = .success(NodeEntity(handle: 1)),
        confirmDecryptionKeyResult: Result<NodeEntity, FileLinkFlowErrorEntity> = .success(NodeEntity(handle: 1)),
        resolvedLink: String? = nil
    ) {
        self.initialStartResult = initialStartResult
        self.confirmDecryptionKeyResult = confirmDecryptionKeyResult
        self.resolvedLink = resolvedLink
    }

    func initialStart(with link: String) async throws(FileLinkFlowErrorEntity) -> ResolvedFileLinkEntity {
        await whileInFlight?()
        return ResolvedFileLinkEntity(node: try initialStartResult.get(), link: resolvedLink ?? link)
    }

    func confirmDecryptionKey(
        with link: String,
        decryptionKey: String
    ) async throws(FileLinkFlowErrorEntity) -> ResolvedFileLinkEntity {
        confirmDecryptionKeyCalledArguments.append((link, decryptionKey))
        await whileInFlight?()
        return ResolvedFileLinkEntity(node: try confirmDecryptionKeyResult.get(), link: resolvedLink ?? link)
    }
}
