
import Foundation
import CoreData

extension MEGAStore {
    /// Fetch message from Core Data
    /// - Parameters:
    ///   - msgId: The id of the message
    ///   - chatId: The id of the chat
    ///   - context: The managed object context used for fetching the message
    /// - Returns: Return the managed object message
    func fetchMessage(msgId: UInt64, chatId: UInt64, context: NSManagedObjectContext) -> MOMessage? {
        let fetchRequest = MOMessage.fetchRequest()
        fetchRequest.fetchLimit = 1
        fetchRequest.predicate = NSPredicate(
            format: "chatId == %llu AND messageId == %llu", chatId, msgId
        )
        var messages: [MOMessage] = []
        do {
          messages = try context.fetch(fetchRequest)
        } catch let error {
          MEGALogError("Failed to fetch message: \(error)")
        }
        return messages.first
    }
    
    /// Delete Managed Object message from Core Data
    /// - Parameters:
    ///   - message: The managed object message that will be deleted
    ///   - context: The managed object context used for deleting the message
    func delete(message: MOMessage, context: NSManagedObjectContext) {
        context.delete(message)
        save(context)
    }
}
