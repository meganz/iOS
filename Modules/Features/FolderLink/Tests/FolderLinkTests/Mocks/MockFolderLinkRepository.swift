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
    private(set) var retryPendingConnectionsCalled = false
    private let childrenByHandle: [HandleEntity: [NodeEntity]]
    private let nodesByHandle: [HandleEntity: NodeEntity]
    
    init(
        loginResult: Result<Void, any Error> = .success,
        fetchNodesResult: Result<Void, any Error> = .success,
        rootNode: HandleEntity = .invalid,
        childrenByHandle: [HandleEntity: [NodeEntity]] = [:],
        nodesByHandle: [HandleEntity: NodeEntity] = [:],
        logoutHandler: @escaping @Sendable () -> Void = { }
    ) {
        self.loginResult = loginResult
        self.fetchNodesResult = fetchNodesResult
        self.rootNode = rootNode
        self.childrenByHandle = childrenByHandle
        self.nodesByHandle = nodesByHandle
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
    
    func children(of nodeHandle: MEGADomain.HandleEntity) -> [NodeEntity] {
        childrenByHandle[nodeHandle] ?? []
    }
    
    func node(for handle: MEGADomain.HandleEntity) -> NodeEntity? {
        nodesByHandle[handle]
    }
    
    func retryPendingConnections() {
        retryPendingConnectionsCalled = true
    }
}

