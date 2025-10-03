import MEGASdk

public final class MockFolderSdk: MEGASdk, @unchecked Sendable {
    public var apiURL: String?
    public var disablepkp: Bool?
    private var nodes: [MEGANode]
    private var transferDelegates: [any MEGATransferDelegate] = []
    
    public private(set) var folderLinkLogoutCallCount = 0
    public private(set) var loginToFolderLinkCallCount = 0
    public private(set) var nodeForHandleCallCount = 0
    public private(set) var authorizeNodeCallCount = 0
    
    private var authorizedNodes: [MockNode] = []
    private let errorType: MEGAErrorType
    
    public override func changeApiUrl(_ apiURL: String, disablepkp: Bool) {
        self.apiURL = apiURL
        self.disablepkp = disablepkp
    }
    
    public init(
        isLoggedIn: Bool = false,
        nodes: [MEGANode] = [],
        errorType: MEGAErrorType = .apiOk
    ) {
        self.apiURL = isLoggedIn ? "any-url" : nil
        self.nodes = nodes
        self.errorType = errorType
        super.init()
    }
    
    public override func logout() {
        folderLinkLogoutCallCount += 1
        apiURL = nil
    }
    
    public override func isLoggedIn() -> Int {
        return apiURL == nil ? 0 : 1
    }
    
    public override func login(toFolderLink folderLink: String) {
        loginToFolderLinkCallCount += 1
        apiURL = "any-url"
    }
    
    public override func node(forHandle handle: UInt64) -> MEGANode? {
        nodeForHandleCallCount += 1
        return nodes.first { $0.handle == handle }
    }
    
    public override func authorizeNode(_ node: MEGANode) -> MEGANode? {
        authorizeNodeCallCount += 1
        
        return authorizedNodes.filter {$0.handle == node.handle}.first
    }
    
    public func mockAuthorizeNode(with node: MockNode) {
        authorizedNodes.append(node)
    }
    
    public override func children(forParent parent: MEGANode, order: Int) -> MEGANodeList {
        let children = nodes.filter { $0.parentHandle == parent.handle }
        return MockNodeList(nodes: children)
    }
    
    public override func getDownloadUrl(_ node: MEGANode, singleUrl: Bool, delegate: any MEGARequestDelegate) {
        let request = MEGARequest()
        let error = MockError(errorType: errorType)
        delegate.onRequestFinish?(self, request: request, error: error)
    }
    
    public override func add(_ delegate: any MEGATransferDelegate) {
        transferDelegates.append(delegate)
    }
    
    public override func remove(_ delegate: any MEGATransferDelegate) {
        transferDelegates.removeAll { $0 === delegate }
    }
    
    // MARK: - Simulate delegate callback
    public func simulateOnTransferFinish(_ transfer: MEGATransfer, error: MEGAError) {
        transferDelegates.forEach {
            $0.onTransferFinish?(self, transfer: transfer, error: error)
        }
    }
}
