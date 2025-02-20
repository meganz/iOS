import MEGADomain
import MEGASdk

extension MEGANodeList {
    @objc public func toNodeArray() -> [MEGANode] {
        guard size > 0 else { return [] }
        return (0..<size).compactMap { node(at: $0) }
    }
    
    public func toNodeEntities() -> [NodeEntity] {
        guard size > 0 else { return [] }
        return (0..<size).compactMap { node(at: $0)?.toNodeEntity() }
    }
    
    public func toPlayableNodeArray() -> [MEGANode] {
        guard size > 0 else { return [] }
        return (0..<size).compactMap {
            guard let node = node(at: $0),
                let name = node.name else { return nil }
            let group = name.fileExtensionGroup
            guard group.isAudio else {
                return nil
            }
            return node
        }
    }
}
