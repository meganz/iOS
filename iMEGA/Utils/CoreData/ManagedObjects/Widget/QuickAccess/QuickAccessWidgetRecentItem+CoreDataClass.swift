
import CoreData
import Foundation

public class QuickAccessWidgetRecentItem: NSManagedObject {

    static func createInstance(withContext context: NSManagedObjectContext) -> QuickAccessWidgetRecentItem {
        guard let quickAccessWidgetRecentItem = NSEntityDescription.insertNewObject(forEntityName: "QuickAccessWidgetRecentItem", into: context) as? QuickAccessWidgetRecentItem else {
            fatalError("couldnot create instance of QuickAccessWidgetRecentItem")
        }
        return quickAccessWidgetRecentItem
    }
    
}
