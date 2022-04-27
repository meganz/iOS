
extension Sequence where Element: MEGANode {
    func containsNewNode() -> Bool {
        !filter({ $0.hasChangedType(.new) }).isEmpty
    }
    
    func intersection(_ nodes: [MEGANode]) -> [MEGANode] {
        return filter { node in
            return !nodes.filter({ $0 == node}).isEmpty
        }
    }
    
    func hasModifiedAttributes() -> Bool {
        !filter({ $0.hasChangedType(.attributes)}).isEmpty
    }
    
    func hasModifiedParent() -> Bool {
        !filter({ $0.hasChangedType(.parent)}).isEmpty
    }
    
    func modifiedFavourites() -> [MEGANode] {
        filter({ $0.hasChangedType(.favourite) })
    }
}
