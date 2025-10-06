import MEGADomain
import MEGASdk

extension MEGANode: @retroactive PlayableNode {
    public var id: String {
        return String(handle)
    }
}
