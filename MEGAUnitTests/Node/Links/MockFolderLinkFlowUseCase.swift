@testable import MEGA

final class MockFolderLinkFlowUseCase: FolderLinkFlowUseCaseProtocol, @unchecked Sendable {
    private(set) var stopCalled = false
    private let initialStartResult: Result<Void, FolderLinkFlowErrorEntity>
    private let confirmDecryptionKeyResult: Result<Void, FolderLinkFlowErrorEntity>
    
    init(
        initialStartResult: Result<Void, FolderLinkFlowErrorEntity> = .success(()),
        confirmDecryptionKeyResult: Result<Void, FolderLinkFlowErrorEntity> = .success(())
    ) {
        self.initialStartResult = initialStartResult
        self.confirmDecryptionKeyResult = confirmDecryptionKeyResult
    }

    func initialStart(with link: String) async throws(FolderLinkFlowErrorEntity) {
        try initialStartResult.get()
    }
    
    func confirmDecryptionKey(with link: String, decryptionKey: String) async throws(FolderLinkFlowErrorEntity) {
        try confirmDecryptionKeyResult.get()
    }
    
    func stop() { stopCalled = true }
}
