
import Foundation
import CoreData

public class ChatUploadTransfer: NSManagedObject {
    
    static func createInstance(withContext context: NSManagedObjectContext) -> ChatUploadTransfer {
        guard let chatUploadTransfer = NSEntityDescription.insertNewObject(forEntityName: "ChatUploadTransfer", into: context) as? ChatUploadTransfer else {
            fatalError("couldnot create instance of ChatUploadTransfer")
        }
        return chatUploadTransfer
    }

}
