import MEGAChatSdk
import MEGADomain
import MEGASwift

public protocol ChatRoomUpdateProviderProtocol: Sendable {
    /// ChatRoom updates from `MEGAChatRoomDelegate` `onChatRoomUpdate` as an `AnyAsyncSequence`
    ///
    /// - Returns: `AnyAsyncSequence` that will call chatSdk.add on creation and chatSdk.remove onTermination of `AsyncStream`.
    /// It will yield `ChatRoomEntity` item until sequence terminated
    var chatRoomUpdate: AnyAsyncSequence<ChatRoomEntity> { get }
}

public struct ChatRoomUpdateProvider: ChatRoomUpdateProviderProtocol {
    public var chatRoomUpdate: AnyAsyncSequence<ChatRoomEntity> {
        AsyncStream { continuation in
            let delegate = ChatRoomUpdateGlobalDelegate {
                continuation.yield($0)
            }
            continuation.onTermination = { _ in
                sdk.removeChatRoomDelegate(chatId, delegate: delegate)
            }
            sdk.addChatRoomDelegate(chatId, delegate: delegate)
        }
        .eraseToAnyAsyncSequence()
    }
    
    private let sdk: MEGAChatSdk
    private let chatId: ChatIdEntity

    public init(sdk: MEGAChatSdk, chatId: ChatIdEntity) {
        self.sdk = sdk
        self.chatId = chatId
    }
}

private final class ChatRoomUpdateGlobalDelegate: NSObject, MEGAChatRoomDelegate {
    private let onChatRoomUpdate: (ChatRoomEntity) -> Void
    
    public init(onUpdate: @escaping (ChatRoomEntity) -> Void) {
        self.onChatRoomUpdate = onUpdate
        super.init()
    }
    
    func onChatRoomUpdate(_ api: MEGAChatSdk, chat: MEGAChatRoom) {
        onChatRoomUpdate(chat.toChatRoomEntity())
    }
}
