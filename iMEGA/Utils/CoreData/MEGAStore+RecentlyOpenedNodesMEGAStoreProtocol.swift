import CoreData
import Foundation
import MEGADomain
import MEGASDKRepo

extension MEGAStore: RecentlyOpenedNodesMEGAStoreProtocol {
    
    public func fetchRecentlyOpenedNodes() async throws -> [RecentlyOpenedNodeRepositoryDTO] {
        guard let context = stack.newBackgroundContext() else {
            throw RecentlyOpenedNodesErrorEntity.couldNotCreateNewBackgroundContext
        }
        return try await context.perform {
            let fetchRequest: NSFetchRequest<MORecentlyOpenedNode> = MORecentlyOpenedNode.fetchRequest()
            fetchRequest.relationshipKeyPathsForPrefetching = ["mediaDestination"]
            let nodes = try context.fetch(fetchRequest)
            return nodes.map { $0.toRecentlyOpenedNodeRepositoryDTO() }
        }
    }
    
    public func insertOrUpdateRecentlyOpenedNode(fingerprint: String, destination: Int, timescale: Int?, lastOpenedDate: Date) {
        guard let context = stack.viewContext else { return }
        
        guard let moMediaDestination: MOMediaDestination = {
            if let existingMediaDestination = fetchMediaDestination(withFingerprint: fingerprint) {
                existingMediaDestination.destination = destination as NSNumber
                existingMediaDestination.timescale = timescale as? NSNumber
                return existingMediaDestination
            } else {
                guard let mediaDestination = NSEntityDescription.insertNewObject(forEntityName: "MediaDestination", into: context) as? MOMediaDestination else {
                    MEGALogError("could not create instance of MOMediaDestination")
                    return nil
                }
                mediaDestination.fingerprint = fingerprint
                mediaDestination.destination = destination as NSNumber
                mediaDestination.timescale = timescale as? NSNumber
                return mediaDestination
            }
        }() else {
            return
        }
        
        if let existingRecentlyOpenedNode = fetchRecentlyOpenedNode(fingerprint: fingerprint) {
            existingRecentlyOpenedNode.lastOpenedDate = lastOpenedDate
            existingRecentlyOpenedNode.mediaDestination = moMediaDestination
            
            logRecentlyOpenedNode(existingRecentlyOpenedNode)
        } else {
            guard let recentlyOpenedNode = NSEntityDescription.insertNewObject(forEntityName: "MORecentlyOpenedNode", into: context) as? MORecentlyOpenedNode else {
                MEGALogError("could not create instance of MORecentlyOpenedNode")
                return
            }
            recentlyOpenedNode.fingerprint = fingerprint
            recentlyOpenedNode.lastOpenedDate = lastOpenedDate
            recentlyOpenedNode.mediaDestination = moMediaDestination
            
            logRecentlyOpenedNode(recentlyOpenedNode)
        }
        
        MEGAStore.shareInstance().save(context)
    }
    
    @objc func fetchRecentlyOpenedNode(fingerprint: String) -> MORecentlyOpenedNode? {
        guard let context = stack.viewContext else {
            MEGALogError("\(type(of: MEGAStore.self)) Failed to create ManagedObjectContext when fetching recently opened node with fingerprint: \(fingerprint)")
            return nil
        }
        
        let request: NSFetchRequest<MORecentlyOpenedNode> = MORecentlyOpenedNode.fetchRequest()
        request.predicate = NSPredicate(format: "fingerprint == %@", fingerprint)
        
        do {
            return try context.fetch(request).first
        } catch {
            MEGALogError("\(type(of: MEGAStore.self)) Failed to fetch recently opened node: \(error)")
            return nil
        }
    }
    
    private func logRecentlyOpenedNode(_ moRecentlyOpenedNode: MORecentlyOpenedNode) {
        let moMediaDestination = moRecentlyOpenedNode.mediaDestination
        MEGALogError("Save context - update recently opened node with fingerprint: \(String(describing: moRecentlyOpenedNode.fingerprint)), last opened date: \(String(describing: moRecentlyOpenedNode.lastOpenedDate)), destination: \(String(describing: moMediaDestination?.destination)), timescale: \(String(describing: moMediaDestination?.timescale))")
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
