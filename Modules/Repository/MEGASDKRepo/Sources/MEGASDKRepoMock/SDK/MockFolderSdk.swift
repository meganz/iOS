import MEGASdk

public final class MockFolderSdk: MEGASdk {
    public var apiURL: String?
    public var disablepkp: Bool?
    private var nodes: [MEGANode]
    private var transferDelegates: [any MEGATransferDelegate] = []
    
    public private(set) var folderLinkLogoutCallCount = 0
    public private(set) var loginToFolderLinkCallCount = 0
    public private(set) var nodeForHandleCallCount = 0
    public private(set) var authorizeNodeCallCount = 0
    
    private var authorizeNode: MockNode?
    
    public override func changeApiUrl(_ apiURL: String, disablepkp: Bool) {
        self.apiURL = apiURL
        self.disablepkp = disablepkp
    }
    
    public init(isLoggedIn: Bool = false, nodes: [MEGANode] = []) {
        self.apiURL = isLoggedIn ? "any-url" : nil
        self.nodes = nodes
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
        
        if let authorizeNode {
            return authorizeNode
        }
        
        return nil
    }
    
    public func mockAuthorizeNode(with node: MockNode) {
        authorizeNode = node
    }
    
    public override func children(forParent parent: MEGANode, order: Int) -> MEGANodeList {
        let children = nodes.filter { $0.parentHandle == parent.handle }
        return MockNodeList(nodes: children)
    }
    
    public override func getDownloadUrl(_ node: MEGANode, singleUrl: Bool, delegate: MEGARequestDelegate) { }
    
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
