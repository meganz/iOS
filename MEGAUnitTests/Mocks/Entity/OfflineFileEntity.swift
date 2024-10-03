import CoreData
import MEGADomain

@testable import MEGA

extension OfflineFileEntity {
    public func toMOOfflineNode(in context: NSManagedObjectContext) -> MOOfflineNode {
        let moOfflineNode = MOOfflineNode(context: context)
        moOfflineNode.base64Handle = self.base64Handle
        moOfflineNode.localPath = self.localPath
        return moOfflineNode
    }
}
