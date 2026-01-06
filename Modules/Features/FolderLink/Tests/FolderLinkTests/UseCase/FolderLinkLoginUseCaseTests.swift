import FolderLink
import MEGAAppSDKRepoMock
import MEGADomain
import Testing

struct FolderLinkLoginUseCaseTests {
    @Test("login succeeds")
    func loginDoesNotThrowWhenSuccess() async throws {
        let repo = MockFolderLinkRepository()
        let sut = FolderLinkLoginUseCase(folderLinkRepository: repo)
        try await sut.login(to: "some_link")
    }

    @Test("login rethrows known domain error")
    func loginThrowsKnownError() async {
        let repo = MockFolderLinkRepository(
            loginResult: .failure(FolderLinkLoginErrorEntity.missingDecryptionKey)
        )
        
        let sut = FolderLinkLoginUseCase(folderLinkRepository: repo)

        await #expect(throws: FolderLinkLoginErrorEntity.missingDecryptionKey) {
            try await sut.login(to: "some_link")
        }
    }

    @Test("login wraps unknown error into .generic")
    func loginThrowsGenericError() async {
        let repo = MockFolderLinkRepository(loginResult: .failure(MockError()))
        let sut = FolderLinkLoginUseCase(folderLinkRepository: repo)

        await #expect(throws: FolderLinkLoginErrorEntity.linkUnavailable(.generic)) {
            try await sut.login(to: "some_link")
        }
    }
}
