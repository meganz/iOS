import MEGADomain

extension NodeTypeEntity {
    init?(nodeType: MEGANodeType) {
        self.init(rawValue: nodeType.rawValue)
    }
}
