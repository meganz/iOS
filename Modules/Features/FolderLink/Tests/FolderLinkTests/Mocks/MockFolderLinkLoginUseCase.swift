import FolderLink

final class MockFolderLinkLoginUseCase: FolderLinkLoginUseCaseProtocol, @unchecked Sendable {
    var loggedInLink: String?
    private let loginResult: Result<Void, FolderLinkLoginErrorEntity>
    
    init(loginResult: Result<Void, FolderLinkLoginErrorEntity> = .success) {
        self.loginResult = loginResult
    }
    
    func login(to link: String) async throws(FolderLinkLoginErrorEntity) {
        loggedInLink = link
        return try loginResult.get()
    }
}
