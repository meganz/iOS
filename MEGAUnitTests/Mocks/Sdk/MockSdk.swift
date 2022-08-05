import Foundation
@testable import MEGA
import MEGADomain

final class MockSdk: MEGASdk {
    private var nodes: [MEGANode]
    private let rubbishNodes: [MEGANode]
    private let myContacts: MEGAUserList
    private let user: MEGAUser?
    private let email: String?
    private var statsEventType: Int?
    private var statsEventMessage: String?
    
    init(nodes: [MEGANode] = [],
         rubbishNodes: [MEGANode] = [],
         myContacts: MEGAUserList = MEGAUserList(),
         myUser: MEGAUser? = nil,
         myEmail: String? = nil) {
        self.nodes = nodes
        self.rubbishNodes = rubbishNodes
        self.myContacts = myContacts
        user = myUser
        email = myEmail
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
    
    override func contacts() -> MEGAUserList { myContacts }
    
    override func sendEvent(_ eventType: Int, message: String) {
        statsEventType = eventType
        statsEventMessage = message
    }
    
    func isLastSentEvent(eventType type: Int, message: String) -> Bool {
        statsEventType == type && statsEventMessage == message
    }
}
