import ChatRepo
import MEGAChatSdk

public final class MockChatSDK: MEGAChatSdk {
    private let chatRoom: MEGAChatRoom?
    private let hasChatOptionEnabled: Bool
    
    public var autojoinPublicChatCalled = 0
    public var autorejoinPublicChatCalled = 0
    
    public var hasChatCallDelegate = false
    public var delegateQueueType: ListenerQueueType?

    public init(
        chatRoom: MEGAChatRoom? = MockChatRoom(),
        hasChatOptionEnabled: Bool = false
    ) {
        self.chatRoom = chatRoom
        self.hasChatOptionEnabled = hasChatOptionEnabled
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
    
    public override func hasChatOptionEnabled(for option: MEGAChatOption, chatOptionsBitMask: Int) -> Bool {
        hasChatOptionEnabled
    }
    
    public override func add(_ delegate: MEGAChatCallDelegate, queueType: ListenerQueueType) {
        hasChatCallDelegate = true
        delegateQueueType = queueType
    }
    
    public override func remove(_ delegate: any MEGAChatCallDelegate) {
        hasChatCallDelegate = false
    }
}
