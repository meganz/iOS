
import Foundation
import CoreData


extension QuickAccessWidgetFavouriteItem {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<QuickAccessWidgetFavouriteItem> {
        return NSFetchRequest<QuickAccessWidgetFavouriteItem>(entityName: "QuickAccessWidgetFavouriteItem")
    }

    @NSManaged public var handle: String?
    @NSManaged public var timestamp: Date?
    @NSManaged public var name: String?

}
