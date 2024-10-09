import CoreData
import Foundation
import MEGADomain
import MEGASDKRepo

extension MEGAStore: RecentlyOpenedNodesMEGAStoreProtocol {
    
    public func fetchRecentlyOpenedNodes() async throws -> [RecentlyOpenedNodeRepositoryDTO] {
        try await fetchRecentlyOpenedNodes()
            .toRecentlyOpenedNodeRepositoryDTOs()
    }
    
    private func fetchRecentlyOpenedNodes() async throws -> [MORecentlyOpenedNode] {
        guard let context = stack.newBackgroundContext() else {
            throw RecentlyOpenedNodesErrorEntity.couldNotCreateNewBackgroundContext
        }
        let fetchRequest: NSFetchRequest<MORecentlyOpenedNode> = MORecentlyOpenedNode.fetchRequest()
        fetchRequest.relationshipKeyPathsForPrefetching = ["mediaDestination"]
        return try context.fetch(fetchRequest)
    }
    
    public func insertOrUpdateMediaDestination(fingerprint: String, destination: Int, timescale: Int?) {
        insertOrUpdateMediaDestination(
            withFingerprint: fingerprint,
            destination: destination as NSNumber,
            timescale: timescale as? NSNumber
        )
    }
    
    public func clearRecentlyOpenedNodes() async throws {
        guard let context = stack.newBackgroundContext() else {
            throw RecentlyOpenedNodesErrorEntity.couldNotCreateNewBackgroundContext
        }
        return try await context.perform {
            let fetchRequest: NSFetchRequest<any NSFetchRequestResult> = MORecentlyOpenedNode.fetchRequest()
            fetchRequest.includesPropertyValues = false
            let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            try context.execute(batchDeleteRequest)
            try context.save()
        }
    }
}
