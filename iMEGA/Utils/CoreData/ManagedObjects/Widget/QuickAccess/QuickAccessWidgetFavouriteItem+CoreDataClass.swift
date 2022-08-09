
import Foundation
import CoreData


public class QuickAccessWidgetFavouriteItem: NSManagedObject {

    static func createInstance(withContext context: NSManagedObjectContext) -> QuickAccessWidgetFavouriteItem {
        guard let quickAccessWidgetFavouriteItem = NSEntityDescription.insertNewObject(forEntityName: "QuickAccessWidgetFavouriteItem", into: context) as? QuickAccessWidgetFavouriteItem else {
            fatalError("couldnot create instance of QuickAccessWidgetFavouriteItem")
        }
        return quickAccessWidgetFavouriteItem
    }
    
}
