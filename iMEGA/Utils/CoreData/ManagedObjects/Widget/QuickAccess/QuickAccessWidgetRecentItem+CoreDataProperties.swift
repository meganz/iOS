
import CoreData
import Foundation

extension QuickAccessWidgetRecentItem {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<QuickAccessWidgetRecentItem> {
        return NSFetchRequest<QuickAccessWidgetRecentItem>(entityName: "QuickAccessWidgetRecentItem")
    }

    @NSManaged public var handle: String?
    @NSManaged public var timestamp: Date?
    @NSManaged public var name: String?
    @NSManaged public var isUpdate: NSNumber?

}
