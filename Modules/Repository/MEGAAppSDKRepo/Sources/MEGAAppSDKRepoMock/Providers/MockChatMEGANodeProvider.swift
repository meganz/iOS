import MEGAAppSDKRepo
import MEGADomain
import MEGASdk

public struct MockChatMEGANodeProvider: ChatMEGANodeProviding {
    private let node: MEGANode?

    public init(node: MEGANode? = nil) {
        self.node = node
    }

    public func node(
        handle: HandleEntity,
        messageId: HandleEntity,
        chatId: HandleEntity
    ) async -> MEGANode? {
        node
    }
}
