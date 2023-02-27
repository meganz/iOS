import MEGADomain

struct NodeAttributeRepository: NodeAttributeRepositoryProtocol {
    static var newRepo: NodeAttributeRepository {
        NodeAttributeRepository(sdk: MEGASdk.shared)
    }
    
    private let sdk: MEGASdk
    
    init(sdk: MEGASdk) {
        self.sdk = sdk
    }
    
    func pathFor(node: NodeEntity) -> String? {
        guard let megaNode = sdk.node(forHandle: node.handle) else {
            return nil
        }
        return sdk.nodePath(for: megaNode)
    }
    
    func numberChildrenFor(node: NodeEntity) -> Int {
        guard let megaNode = sdk.node(forHandle: node.handle) else {
            return 0
        }
        return sdk.numberChildren(forParent: megaNode)
    }
    
    func isInRubbishBin(node: NodeEntity) -> Bool {
        guard let megaNode = sdk.node(forHandle: node.handle) else {
            return false
        }
        return sdk.isNode(inRubbish: megaNode)
    }
}
