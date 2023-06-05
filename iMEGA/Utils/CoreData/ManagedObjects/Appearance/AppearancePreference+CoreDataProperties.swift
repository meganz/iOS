
import Foundation
import CoreData

extension AppearancePreference {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<AppearancePreference> {
        return NSFetchRequest<AppearancePreference>(entityName: "AppearancePreference")
    }

    @NSManaged public var sortType: NSNumber?
    @NSManaged public var viewMode: NSNumber?

}
