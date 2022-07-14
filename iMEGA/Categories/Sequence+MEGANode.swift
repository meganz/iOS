extension Sequence where Element: MEGANode {
    func containsNewNode() -> Bool {
        !filter({ $0.hasChangedType(.new) }).isEmpty
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
    
    func removedChangeTypeNodes() -> [MEGANode] {
        nodes(for: [.removed, .parent])
    }
    
    func hasPublicLink() -> Bool {
        !filter({
            $0.hasChangedType(.publicLink) &&
            $0.publicLink != nil
        }).isEmpty
    }
    
    func isPublicLinkRemoved() -> Bool {
        !filter({
            $0.hasChangedType(.publicLink) &&
            $0.publicLink == nil
        }).isEmpty
    }
    
    func publicLinkedNodes() -> [MEGANode] {
        filter({ $0.isExported() })
    }
    
    func nodes(for changedTypes: [MEGANodeChangeType]) -> [MEGANode] {
        filter {
            for type in changedTypes where $0.hasChangedType(type) {
                return true
            }
            
            return false
        }
    }
}
