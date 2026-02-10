import FolderLink

final class MockFolderLinkPendingConnectionsRetryUseCase: FolderLinkPendingConnectionsRetryUseCaseProtocol, @unchecked Sendable {
    var retryPendingConnectionsCalled = false
    
    func retryPendingConnections() {
        retryPendingConnectionsCalled = true
    }
}

