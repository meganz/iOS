import FolderLink
import MEGADomain
import MEGADomainMock

final class MockFolderLinkFlowUseCase: FolderLinkFlowUseCaseProtocol, @unchecked Sendable {
    private(set) var stopCalled = false
    private(set) var stopCalledArguments: (Bool)?
    
    private let initialStartResult: Result<NodeEntity, FolderLinkFlowErrorEntity>
    private let confirmDecryptionKeyResult: Result<NodeEntity, FolderLinkFlowErrorEntity>

    init(
        initialStartResult: Result<NodeEntity, FolderLinkFlowErrorEntity> = .success(NodeEntity()),
        confirmDecryptionKeyResult: Result<NodeEntity, FolderLinkFlowErrorEntity> = .success(NodeEntity())
    ) {
        self.initialStartResult = initialStartResult
        self.confirmDecryptionKeyResult = confirmDecryptionKeyResult
    }

    func initialStart(with link: String) async throws(FolderLinkFlowErrorEntity) -> NodeEntity {
        try initialStartResult.get()
    }

    func confirmDecryptionKey(with link: String, decryptionKey: String) async throws(FolderLinkFlowErrorEntity) -> NodeEntity {
        try confirmDecryptionKeyResult.get()
    }
    
    func stop(shouldLogout: Bool) {
        stopCalledArguments = (shouldLogout)
        stopCalled = true
    }
}
