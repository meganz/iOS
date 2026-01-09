import FolderLink
import MEGADomain

final class MockFolderLinkFlowUseCase: FolderLinkFlowUseCaseProtocol, @unchecked Sendable {
    private(set) var stopCalled = false
    private let initialStartResult: Result<HandleEntity, FolderLinkFlowErrorEntity>
    private let confirmDecryptionKeyResult: Result<HandleEntity, FolderLinkFlowErrorEntity>
    
    init(
        initialStartResult: Result<HandleEntity, FolderLinkFlowErrorEntity> = .success(.invalid),
        confirmDecryptionKeyResult: Result<HandleEntity, FolderLinkFlowErrorEntity> = .success(.invalid)
    ) {
        self.initialStartResult = initialStartResult
        self.confirmDecryptionKeyResult = confirmDecryptionKeyResult
    }

    func initialStart(with link: String) async throws(FolderLinkFlowErrorEntity) -> HandleEntity {
        try initialStartResult.get()
    }
    
    func confirmDecryptionKey(with link: String, decryptionKey: String) async throws(FolderLinkFlowErrorEntity) -> HandleEntity {
        try confirmDecryptionKeyResult.get()
    }
    
    func stop() { stopCalled = true }
}
