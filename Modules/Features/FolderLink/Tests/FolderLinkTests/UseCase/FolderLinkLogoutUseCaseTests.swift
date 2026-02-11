import FolderLink
import MEGADomain
import Testing

struct FolderLinkLogoutUseCaseTests {
    @Test("logout will trigger repository logout")
    func loginWillTriggerRepositoryLogout() async throws {
        // Given
        let repo = MockFolderLinkRepository()
        let sut = FolderLinkLogoutUseCase(folderLinkRepository: repo)
        #expect(repo.logoutCalled == false)
        
        // When
        sut.logout()
        
        // Then
        #expect(repo.logoutCalled == true)
    }
}
