
import Foundation
import CoreData


extension ChatUploadTransfer {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ChatUploadTransfer> {
        return NSFetchRequest<ChatUploadTransfer>(entityName: "ChatUploadTransfer")
    }

    @NSManaged public var index: Int32
    @NSManaged public var filepath: String
    @NSManaged public var transferTag: String?
    @NSManaged public var appData: String?
    @NSManaged public var chatRoomId: String
    @NSManaged public var nodeHandle: String?

}
