import AsyncAlgorithms
import MEGADomain
import MEGASdk
import MEGASwift

private let serialQueue = DispatchQueue(label: "toRecentlyOpenedNodeEntities.serialQueue")

extension Array where Element == RecentlyOpenedNodeRepositoryDTO {
    
    func toRecentlyOpenedNodeEntities(using sdk: MEGASdk) async -> [RecentlyOpenedNodeEntity] {
        let nodes = await self
            .async
            .compactMap { await nodeFor(item: $0, using: sdk) }
            .reduce(into: [NodeEntity](), { @Sendable in $0.append($1) })
        
        return reduce(into: [RecentlyOpenedNodeEntity]()) { result, object in
            if let matchingNode = findNode(for: object.fingerprint, in: nodes) {
                let entity = object.toRecentlyOpenedNodeEntity(node: matchingNode)
                result.append(entity)
            }
        }
    }
    
    private func nodeFor(item: RecentlyOpenedNodeRepositoryDTO, using sdk: MEGASdk) async -> NodeEntity? {
        await withAsyncValue { continuation in
            serialQueue.async {
                guard
                    let fingerprint = item.fingerprint,
                    let node = sdk.node(forFingerprint: fingerprint)
                else {
                    continuation(.success(nil))
                    return
                }
                continuation(.success(node.toNodeEntity()))
            }
        }
    }
    
    private func findNode(for fingerprint: String?, in nodes: [NodeEntity]) -> NodeEntity? {
        guard
            let matchingNode = nodes.first(where: { $0.fingerprint == fingerprint })
        else {
            return nil
        }
        return matchingNode
    }
}
