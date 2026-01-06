import FolderLink

final class MockFolderLinkFetchNodeUseCase: FolderLinkFetchNodesUseCaseProtocol, @unchecked Sendable {
    private(set) var fetchCalled = false
    private let fetchResult: Result<Void, FolderLinkFetchNodesErrorEntity>
    
    init(fetchResult: Result<Void, FolderLinkFetchNodesErrorEntity> = .success) {
        self.fetchResult = fetchResult
    }
    
    func fetchNodes() async throws(FolderLinkFetchNodesErrorEntity) {
        fetchCalled = true
        try fetchResult.get()
    }
}
