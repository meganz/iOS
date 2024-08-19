import MEGAChatSdk
import MEGADomain
import MEGASwift

public protocol ChatListItemUpdateProviderProtocol: Sendable {
    /// ChatRoom updates from `MEGAChatDelegate` `onChatListItemUpdate` as an `AnyAsyncSequence`
    ///
    /// - Returns: `AnyAsyncSequence` that will call chatSdk.add on creation and chatSdk.remove onTermination of `AsyncStream`.
    /// It will yield `ChatListItemEntity` item until sequence terminated
    var chatListItemUpdate: AnyAsyncSequence<ChatListItemEntity> { get }
}

public struct ChatListItemUpdateProvider: ChatListItemUpdateProviderProtocol {
    public var chatListItemUpdate: AnyAsyncSequence<ChatListItemEntity> {
        AsyncStream { continuation in
            let delegate = ChatListItemUpdateGlobalDelegate {
                continuation.yield($0)
            }
            continuation.onTermination = { _ in
                sdk.remove(delegate)
            }
            sdk.add(delegate, queueType: .globalBackground)
        }
        .eraseToAnyAsyncSequence()
    }
    
    private let sdk: MEGAChatSdk
    
    public init(sdk: MEGAChatSdk) {
        self.sdk = sdk
    }
}

private final class ChatListItemUpdateGlobalDelegate: NSObject, MEGAChatDelegate {
    private let onChatListItemUpdate: (ChatListItemEntity) -> Void
    
    public init(onUpdate: @escaping (ChatListItemEntity) -> Void) {
        self.onChatListItemUpdate = onUpdate
        super.init()
    }

    func onChatListItemUpdate(_ api: MEGAChatSdk, item: MEGAChatListItem) {
        onChatListItemUpdate(item.toChatListItemEntity())
    }
}
