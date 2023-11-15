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
}
