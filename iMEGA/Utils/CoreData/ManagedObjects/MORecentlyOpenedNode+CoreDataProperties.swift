import CoreData
import Foundation

extension MORecentlyOpenedNode {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<MORecentlyOpenedNode> {
        return NSFetchRequest<MORecentlyOpenedNode>(entityName: "MORecentlyOpenedNode")
    }
    
    @NSManaged public var fingerprint: String?
    @NSManaged public var lastOpenedDate: Date?
    @NSManaged public var mediaDestination: MOMediaDestination?
    
}

extension MORecentlyOpenedNode: Identifiable {
    
}
