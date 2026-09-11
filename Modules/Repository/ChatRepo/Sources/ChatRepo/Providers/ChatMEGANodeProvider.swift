import MEGAAppSDKRepo
import MEGAChatSdk
import MEGADomain
import MEGAFoundation
import MEGASdk

/// Logic copied from DownloadChatRepository.downloadChat
public struct ChatMEGANodeProvider: ChatMEGANodeProviding {
    private let chatSdk: MEGAChatSdk
    private let sdk: MEGASdk

    public init(chatSdk: MEGAChatSdk, sdk: MEGASdk) {
        self.chatSdk = chatSdk
        self.sdk = sdk
    }

    public func node(
        handle: HandleEntity,
        messageId: HandleEntity,
        chatId: HandleEntity
    ) async -> MEGANode? {
        guard let node = await attachedNode(handle: handle, messageId: messageId, chatId: chatId) else {
            MEGALog.log(
                level: .warning,
                message: "[ChatMEGANodeProvider] no message in chat \(chatId) still carries node \(handle) as message \(messageId)"
            )
            return nil
        }

        guard let chatRoom = chatSdk.chatRoom(forChatId: chatId),
              chatRoom.isPreview,
              let authorizationToken = chatRoom.authorizationToken else {
            return node
        }
        guard let authorizedNode = sdk.authorizeChatNode(node, cauth: authorizationToken) else {
            MEGALog.log(
                level: .warning,
                message: "[ChatMEGANodeProvider] node \(handle) could not be authorised against previewed chat \(chatId)"
            )
            return nil
        }
        return authorizedNode
    }

    private func attachedNode(
        handle: HandleEntity,
        messageId: HandleEntity,
        chatId: HandleEntity
    ) async -> MEGANode? {
        if let node = await chatSdk.message(chatId: chatId, messageId: messageId)?.nodeList?.node(at: 0),
           node.handle == handle {
            return node
        }

        if let node = await chatSdk.messageFromNodeHistory(chatId: chatId, messageId: messageId)?.nodeList?.node(at: 0),
           node.handle == handle {
            return node
        }

        return nil
    }
}
