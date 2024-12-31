import MEGAChatSdk

private let messageQueue = DispatchQueue(label: "com.mega.getMessageQueue", qos: .userInitiated)

extension MEGAChatMessage: @retroactive @unchecked Sendable { }

extension MEGAChatSdk {
    /// Retrieves a specific chat message from the MEGAChatSdk in a background thread.
    /// - Parameters:
    ///   - chatId: The ID of the chat.
    ///   - messageId: The ID of the message.
    ///   - completion: A closure that is called when the message is retrieved. The closure takes an optional `MEGAChatMessage` parameter, which represents the retrieved message.
    ///
    /// - Note:
    ///     This method is asynchronous and the completion closure is called on a background thread.
    ///
    /// - Important:
    ///     The `completion` closure is called with the retrieved message or `nil` if the message is not found.
    func message(chatId: MEGAHandle, messageId: MEGAHandle, completion: @Sendable @escaping (MEGAChatMessage?) -> Void) {
        messageQueue.async { [weak self] in
            completion(self?.message(forChat: chatId, messageId: messageId))
        }
    }
    
    /// Retrieves a specific chat message
    /// - Parameters:
    ///   - chatId: The ID of the chat.
    ///   - messageId: The ID of the message.
    /// - Returns: the retrieved message or `nil` if the message is not found.
    func message(chatId: MEGAHandle, messageId: MEGAHandle) async -> MEGAChatMessage? {
        await withCheckedContinuation { continuation in
            message(chatId: chatId, messageId: messageId) { message in
                continuation.resume(returning: message)
            }
        }
    }
    
    /// Retrieves a specific chat message from the MEGAChatSdk in a background thread.
    /// - Parameters:
    ///   - chatId: The ID of the chat.
    ///   - messageId: The ID of the message.
    ///   - completion: A closure that is called when the message is retrieved. The closure takes an optional `MEGAChatMessage` parameter, which represents the retrieved message.
    ///
    /// - Note:
    ///     This method is asynchronous and the completion closure is called on a background thread.
    ///
    /// - Important:
    ///     The `completion` closure is called with the retrieved message or `nil` if the message is not found.
    func messageFromNodeHistory(chatId: MEGAHandle, messageId: MEGAHandle, completion: @Sendable @escaping (MEGAChatMessage?) -> Void) {
        messageQueue.async { [weak self] in
            completion(self?.messageFromNodeHistory(forChat: chatId, messageId: messageId))
        }
    }
    
    /// Retrieves a specific chat message
    /// - Parameters:
    ///   - chatId: The ID of the chat.
    ///   - messageId: The ID of the message.
    /// - Returns: the retrieved message or `nil` if the message is not found.
    func messageFromNodeHistory(chatId: MEGAHandle, messageId: MEGAHandle) async -> MEGAChatMessage? {
        await withCheckedContinuation { continuation in
            messageFromNodeHistory(chatId: chatId, messageId: messageId) { message in
                continuation.resume(returning: message)
            }
        }
    }
}
