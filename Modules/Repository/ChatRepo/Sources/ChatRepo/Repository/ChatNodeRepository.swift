import MEGAChatSdk
import MEGADomain

public struct ChatNodeRepository: ChatNodeRepositoryProtocol {
    public static var newRepo: ChatNodeRepository {
        ChatNodeRepository(chatSdk: MEGAChatSdk.sharedChatSdk)
    }
    
    private let chatSdk: MEGAChatSdk
    
    private init(chatSdk: MEGAChatSdk) {
        self.chatSdk = chatSdk
    }
    
    public func chatNode(handle: HandleEntity, messageId: HandleEntity, chatId: HandleEntity) async -> NodeEntity? {
        if let message = await chatSdk.message(chatId: chatId, messageId: messageId),
           let node = message.nodeList?.node(at: 0),
           handle == node.handle {
            return node.toNodeEntity()
        } else if let messageForNodeHistory = await chatSdk.messageFromNodeHistory(chatId: chatId, messageId: messageId),
                  let node = messageForNodeHistory.nodeList?.node(at: 0),
                  handle == node.handle {
            return node.toNodeEntity()
        } else {
            return nil
        }
    }
}
