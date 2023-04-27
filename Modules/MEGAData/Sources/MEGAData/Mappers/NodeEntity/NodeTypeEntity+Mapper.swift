import MEGADomain
import MEGASdk

extension NodeTypeEntity {
    public init?(nodeType: MEGANodeType) {
        self.init(rawValue: nodeType.rawValue)
    }
}
