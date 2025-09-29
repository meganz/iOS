import MEGAAppSDKRepo
import MEGADomain
import MEGASdk

extension MEGANode: PlayableNode {
    public var nodeHandle: UInt64 {
        handle
    }
    public var id: String {
        return String(handle)
    }

    public var nodeName: String {
        name ?? ""
    }

    public var nodeParentHandle: UInt64 {
        parentHandle
    }
}
