import MEGADomain
import MEGASdk

public struct NodeAttributeRepository: NodeAttributeRepositoryProtocol {
    public static var newRepo: NodeAttributeRepository {
        NodeAttributeRepository(sdk: MEGASdk.sharedSdk)
    }

    private let sdk: MEGASdk

    public init(sdk: MEGASdk) {
        self.sdk = sdk
    }

    public func pathFor(node: NodeEntity) -> String? {
        guard let megaNode = sdk.node(forHandle: node.handle) else {
            return nil
        }
        return sdk.nodePath(for: megaNode)
    }

    public func numberChildrenFor(node: NodeEntity) -> Int {
        guard let megaNode = sdk.node(forHandle: node.handle) else {
            return 0
        }
        return sdk.numberChildren(forParent: megaNode)
    }

    public func isInRubbishBin(node: NodeEntity) -> Bool {
        guard let megaNode = sdk.node(forHandle: node.handle) else {
            return false
        }
        return sdk.isNode(inRubbish: megaNode)
    }
}
