import FolderLink
import MEGADomain
import Testing

struct FolderLinkPendingConnectionRetryUseCaseTests {
    @Test("retryPendingConnections will trigger repository retryPendingConnections")
    func triggerRepositoryRetryPendingConnections() async throws {
        // Given
        let repo = MockFolderLinkRepository()
        let sut = FolderLinkPendingConnectionsRetryUseCase(folderLinkRepository: repo)
        #expect(repo.retryPendingConnectionsCalled == false)
        
        // When
        sut.retryPendingConnections()
        
        // Then
        #expect(repo.retryPendingConnectionsCalled == true)
    }
}
