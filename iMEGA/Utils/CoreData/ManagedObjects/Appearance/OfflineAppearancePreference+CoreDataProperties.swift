
import Foundation
import CoreData


extension OfflineAppearancePreference {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<OfflineAppearancePreference> {
        return NSFetchRequest<OfflineAppearancePreference>(entityName: "OfflineAppearancePreference")
    }

    @NSManaged public var localPath: String?

}
