import MEGADomain
import MEGASdk

/// Resolves a chat attachment to the node it can be downloaded from.
public protocol ChatMEGANodeProviding: Sendable {
    func node(
        handle: HandleEntity,
        messageId: HandleEntity,
        chatId: HandleEntity
    ) async -> MEGANode?
}
