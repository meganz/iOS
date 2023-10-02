import ChatRepo
import MEGAChatSdk

public final class MockChatSDK: MEGAChatSdk {
    private let chatRoom: MEGAChatRoom?
    
    public var autojoinPublicChatCalled = 0
    public var autorejoinPublicChatCalled = 0
    
    public init(
        chatRoom: MEGAChatRoom? = MockChatRoom()
    ) {
        self.chatRoom = chatRoom
        super.init()
    }
    
    public override func chatRoom(forChatId chatId: UInt64) -> MEGAChatRoom? {
        chatRoom
    }
    
    public override func autojoinPublicChat(_ chatId: UInt64, delegate: any MEGAChatRequestDelegate) {
        autojoinPublicChatCalled += 1
        let request = MockChatRequest(chatHandle: chatId)
        delegate.onChatRequestFinish?(self, request: request, error: MockChatError())
    }
    
    public override func autorejoinPublicChat(_ chatId: UInt64, publicHandle: UInt64, delegate: MEGAChatRequestDelegate) {
        autorejoinPublicChatCalled += 1
        let request = MockChatRequest(chatHandle: chatId)
        delegate.onChatRequestFinish?(self, request: request, error: MockChatError())
    }
    
    public override func updateChatPermissions(_ chatId: UInt64, userHandle: UInt64, privilege: Int, delegate: MEGAChatRequestDelegate) {
        let request = MockChatRequest(chatHandle: chatId, privilege: privilege)
        delegate.onChatRequestFinish?(self, request: request, error: MockChatError())
    }
}
