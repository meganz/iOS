@preconcurrency import CoreData
import Foundation

extension MEGAStore: @unchecked Sendable {}

extension MEGAStore {
    /// The local path of each node's offline copy, in one fetch. Nodes with no offline record are
    /// absent from the result
    func offlineLocalPaths(for nodes: [MEGANode]) -> [MEGANode: String] {
        let context = Thread.isMainThread ? managedObjectContext : newBackgroundObjectContext()
        guard let context else { return [:] }
        return offlineLocalPaths(for: nodes, context: context)
    }

    /// `offlineNode(with:context:)` for a whole list in one fetch, reading each record's local path
    func offlineLocalPaths(for nodes: [MEGANode], context: NSManagedObjectContext) -> [MEGANode: String] {
        guard !nodes.isEmpty else { return [:] }

        let fingerprints = Set(nodes.compactMap(\.fingerprint))
        let handles = Set(nodes.filter { $0.fingerprint == nil }.compactMap(\.base64Handle))

        return context.performAndWait {
            let request = NSFetchRequest<MOOfflineNode>(entityName: "OfflineNode")
            request.predicate = NSPredicate(format: "fingerprint IN %@ OR base64Handle IN %@", fingerprints, handles)
            let records = (try? context.fetch(request)) ?? []

            // First match wins, as `firstObject` does per node.
            let byFingerprint = Dictionary(records.compactMap { r in r.fingerprint.map { ($0, r.localPath) } }, uniquingKeysWith: { first, _ in first })
            let byHandle = Dictionary(records.map { ($0.base64Handle, $0.localPath) }, uniquingKeysWith: { first, _ in first })

            return nodes.reduce(into: [MEGANode: String]()) { result, node in
                if let fingerprint = node.fingerprint {
                    result[node] = byFingerprint[fingerprint]
                } else if let base64Handle = node.base64Handle {
                    result[node] = byHandle[base64Handle]
                }
            }
        }
    }
}
