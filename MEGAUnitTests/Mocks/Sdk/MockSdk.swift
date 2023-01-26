import Foundation
@testable import MEGA
import MEGADomain

final class MockSdk: MEGASdk {
    private var nodes: [MEGANode]
    private let rubbishNodes: [MEGANode]
    private let syncDebrisNodes: [MEGANode]
    private let myContacts: MEGAUserList
    private let user: MEGAUser?
    private let email: String?
    private var statsEventType: Int?
    private var statsEventMessage: String?
    private let megaRootNode: MEGANode?
    private let rubbishBinNode: MEGANode?
    private let sets: [MEGASet]
    private let setElements: [MEGASetElement]
    private let megaSetElementCounts: [MEGAHandle: UInt]
    
    var hasGlobalDelegate = false
    
    init(nodes: [MEGANode] = [],
         rubbishNodes: [MEGANode] = [],
         syncDebrisNodes: [MEGANode] = [],
         myContacts: MEGAUserList = MEGAUserList(),
         myUser: MEGAUser? = nil,
         myEmail: String? = nil,
         megaSets: [MEGASet] = [],
         megaSetElements: [MEGASetElement] = [],
         megaRootNode: MEGANode? = nil,
         rubbishBinNode: MEGANode? = nil,
         megaSetElementCounts: [MEGAHandle: UInt] = [:]
    ) {
        self.nodes = nodes
        self.rubbishNodes = rubbishNodes
        self.syncDebrisNodes = syncDebrisNodes
        self.myContacts = myContacts
        user = myUser
        email = myEmail
        sets = megaSets
        setElements = megaSetElements
        self.megaRootNode = megaRootNode
        self.rubbishBinNode = rubbishBinNode
        self.megaSetElementCounts = megaSetElementCounts
        super.init()
    }
    
    func setNodes(_ nodes: [MEGANode]) { self.nodes = nodes }
    
    override var myUser: MEGAUser? { user }
    
    override var myEmail: String? { email }
    
    override func node(forHandle handle: HandleEntity) -> MEGANode? {
        nodes.first { $0.handle == handle }
    }
    
    override func parentNode(for node: MEGANode) -> MEGANode? {
        nodes.first { $0.handle == node.parentHandle }
    }
    
    override func isNode(inRubbish node: MEGANode) -> Bool {
        rubbishNodes.contains(node)
    }
    
    override func children(forParent parent: MEGANode) -> MEGANodeList {
        let children = nodes.filter { $0.parentHandle == parent.handle }
        return MockNodeList(nodes: children)
    }
    
    override func children(forParent parent: MEGANode, order: Int) -> MEGANodeList {
        let children = nodes.filter { $0.parentHandle == parent.handle }
        return MockNodeList(nodes: children)
    }
    
    override func contacts() -> MEGAUserList { myContacts }
    
    override func sendEvent(_ eventType: Int, message: String) {
        statsEventType = eventType
        statsEventMessage = message
    }
    
    func isLastSentEvent(eventType type: Int, message: String) -> Bool {
        statsEventType == type && statsEventMessage == message
    }
    
    override func add(_ delegate: MEGAGlobalDelegate) {
        hasGlobalDelegate = true
    }
    
    override func remove(_ delegate: MEGAGlobalDelegate) {
        hasGlobalDelegate = false
    }
    
    override var rootNode: MEGANode? { megaRootNode }
    override var rubbishNode: MEGANode? { rubbishBinNode }
    
    override func nodeListSearch(for node: MEGANode, search searchString: String?, cancelToken: MEGACancelToken, recursive: Bool, orderType: MEGASortOrderType, nodeFormatType: MEGANodeFormatType, folderTargetType: MEGAFolderTargetType) -> MEGANodeList {
        MockNodeList(nodes: nodes)
    }
    
    override func nodePath(for node: MEGANode) -> String? {
        guard let mockNode = node as? MockNode else { return nil }
        
        return mockNode.nodePath
    }
    
    //MARK: - Sets
    
    override func megaSets() -> [MEGASet] {
        sets
    }
    
    override func megaSetElements(bySid sid: MEGAHandle, includeElementsInRubbishBin: Bool) -> [MEGASetElement] {
        setElements
    }
    
    override func megaSetElementCount(_ sid: MEGAHandle, includeElementsInRubbishBin: Bool) -> UInt {
        megaSetElementCounts[sid] ?? 0
    }
    
    override func createSet(_ name: String?, delegate: MEGARequestDelegate) {
        let mockRequest = MockRequest(handle: 1)
        mockRequest.megaSet = MockMEGASet(handle: 1, userId: 0, coverId: 1, name: name ?? "")
        
        delegate.onRequestFinish?(self, request: mockRequest, error: MEGAError())
    }
    
    override func updateSetName(_ sid: MEGAHandle, name: String, delegate: MEGARequestDelegate) {
        let mockRequest = MockRequest(handle: 1)
        mockRequest.megaSetName = name
        
        delegate.onRequestFinish?(self, request: mockRequest, error: MEGAError())
    }
    
    override func removeSet(_ sid: MEGAHandle, delegate: MEGARequestDelegate) {
        let mockRequest = MockRequest(handle: 1)
        mockRequest.megaSetHandle = sid
        
        delegate.onRequestFinish?(self, request: mockRequest, error: MEGAError())
    }
    
    override func createSetElement(_ sid: MEGAHandle, nodeId: MEGAHandle, name: String?, delegate: MEGARequestDelegate) {
        let mockRequest = MockRequest(handle: 1)
        
        delegate.onRequestFinish?(self, request: mockRequest, error: MEGAError())
    }
    
    override func updateSetElement(_ sid: MEGAHandle, eid: MEGAHandle, name: String, delegate: MEGARequestDelegate) {
        let mockRequest = MockRequest(handle: 1)
        mockRequest.megaSetElementName = name
        mockRequest.updateSet = false
        
        delegate.onRequestFinish?(self, request: mockRequest, error: MEGAError())
    }
    
    override func updateSetElementOrder(_ sid: MEGAHandle, eid: MEGAHandle, order: Int64, delegate: MEGARequestDelegate) {
        let mockRequest = MockRequest(handle: 1)
        mockRequest.megaSetElementOrder = order
        
        delegate.onRequestFinish?(self, request: mockRequest, error: MEGAError())
    }
    
    override func removeSetElement(_ sid: MEGAHandle, eid: MEGAHandle, delegate: MEGARequestDelegate) {
        let mockRequest = MockRequest(handle: 1)
        mockRequest.updateSet = false
        
        delegate.onRequestFinish?(self, request: mockRequest, error: MEGAError())
    }
    
    override func putSetCover(_ sid: MEGAHandle, eid: MEGAHandle, delegate: MEGARequestDelegate) {
        let mockRequest = MockRequest(handle: 1)
        mockRequest.megaCoverId = eid
        mockRequest.updateSetCover = true
        
        delegate.onRequestFinish?(self, request: mockRequest, error: MEGAError())
    }
}
