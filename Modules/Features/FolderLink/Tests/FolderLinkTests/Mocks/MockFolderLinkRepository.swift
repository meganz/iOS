import FolderLink
import MEGADomain

final class MockFolderLinkRepository: FolderLinkRepositoryProtocol, @unchecked Sendable {
    static var newRepo: MockFolderLinkRepository {
        MockFolderLinkRepository()
    }
    
    private let loginResult: Result<Void, any Error>
    private let fetchNodesResult: Result<Void, any Error>
    private let rootNode: HandleEntity
    private(set) var logoutCalled = false
    
    init(
        loginResult: Result<Void, any Error> = .success,
        fetchNodesResult: Result<Void, any Error> = .success,
        rootNode: HandleEntity = .invalid,
        logoutHandler: @escaping @Sendable () -> Void = { }
    ) {
        self.loginResult = loginResult
        self.fetchNodesResult = fetchNodesResult
        self.rootNode = rootNode
    }
    
    func loginTo(link: String) async throws {
        try loginResult.get()
    }
    
    func fetchNodes() async throws {
        try fetchNodesResult.get()
    }
    
    func getRootNode() -> HandleEntity {
        rootNode
    }
    
    func logout() {
        logoutCalled = true
    }
}
