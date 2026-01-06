import FolderLink

final class MockFolderLinkLogoutUseCase: FolderLinkLogoutUseCaseProtocol, @unchecked Sendable {
    private(set) var logoutCalled = false
    
    func logout() { logoutCalled = true }
}
