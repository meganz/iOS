import ChatRepo
import MEGAChatSdk

public final class MockChatSDK: MEGAChatSdk, @unchecked Sendable {
    private let chatRoom: MEGAChatRoom?
    private let hasChatOptionEnabled: Bool
    
    private let emailByHandle: [UInt64: String]
    private let userStatus: [UInt64: MEGAChatStatus]
    
    private let chatError: MEGAChatErrorType
    
    private let chatRequest: MEGAChatRequest
    
    public var autojoinPublicChatCalled = 0
    public var autorejoinPublicChatCalled = 0
    
    public var hasChatCallDelegate = false
    public var delegateQueueType: ListenerQueueType?

    public init(
        chatRoom: MEGAChatRoom? = MockChatRoom(),
        hasChatOptionEnabled: Bool = false,
        emailByHandle: [UInt64: String] = [:],
        userStatus: [UInt64: MEGAChatStatus] = [:],
        chatError: MEGAChatErrorType = .MEGAChatErrorTypeOk,
        chatRequest: MEGAChatRequest = MockChatRequest()
    ) {
        self.chatRoom = chatRoom
        self.hasChatOptionEnabled = hasChatOptionEnabled
        self.emailByHandle = emailByHandle
        self.userStatus = userStatus
        self.chatError = chatError
        self.chatRequest = chatRequest
        super.init()
    }
    
    public override func chatRoom(forChatId chatId: UInt64) -> MEGAChatRoom? {
        chatRoom
    }
    
    public override func autojoinPublicChat(_ chatId: UInt64, delegate: any MEGAChatRequestDelegate) {
        autojoinPublicChatCalled += 1
        let request = MockChatRequest(chatHandle: chatId)
        delegate.onChatRequestFinish?(self, request: request, error: MockChatError(chatErrorType: chatError))
    }
    
    public override func autorejoinPublicChat(_ chatId: UInt64, publicHandle: UInt64, delegate: MEGAChatRequestDelegate) {
        autorejoinPublicChatCalled += 1
        let request = MockChatRequest(chatHandle: chatId)
        delegate.onChatRequestFinish?(self, request: request, error: MockChatError(chatErrorType: chatError))
    }
    
    public override func updateChatPermissions(_ chatId: UInt64, userHandle: UInt64, privilege: Int, delegate: MEGAChatRequestDelegate) {
        let request = MockChatRequest(chatHandle: chatId, privilege: privilege)
        delegate.onChatRequestFinish?(self, request: request, error: MockChatError(chatErrorType: chatError))
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
    
    public override func contactEmail(byHandle userHandle: UInt64) -> String? {
        emailByHandle[userHandle]
    }
    
    public override func setWaitingRoom(_ enabled: Bool, chatId: UInt64, delegate: any MEGAChatRequestDelegate) {
        let request = MockChatRequest(chatHandle: chatId, flag: enabled)
        delegate.onChatRequestFinish?(self, request: request, error: MockChatError(chatErrorType: chatError))
    }
    
    public override func archiveChat(_ chatId: UInt64, archive: Bool, delegate: any MEGAChatRequestDelegate) {
        let request = MockChatRequest(chatHandle: chatId, flag: archive)
        delegate.onChatRequestFinish?(self, request: request, error: MockChatError(chatErrorType: chatError))
    }
    
    public override func openInvite(_ enabled: Bool, chatId: UInt64, delegate: any MEGAChatRequestDelegate) {
        let request = MockChatRequest(chatHandle: chatId, flag: enabled)
        delegate.onChatRequestFinish?(self, request: request, error: MockChatError(chatErrorType: chatError))
    }
    
    public override func setChatTitle(_ chatId: UInt64, title: String, delegate: any MEGAChatRequestDelegate) {
        delegate.onChatRequestFinish?(self, request: chatRequest, error: MockChatError(chatErrorType: chatError))
    }
    
    public override func leaveChat(_ chatId: UInt64, delegate: any MEGAChatRequestDelegate) {
        let request = MockChatRequest(chatHandle: chatId)
        delegate.onChatRequestFinish?(self, request: request, error: MockChatError(chatErrorType: chatError))
    }
    
    public override func chatRoom(byUser userHandle: UInt64) -> MEGAChatRoom? {
        chatRoom
    }
    
    public override func userOnlineStatus(_ userHandle: UInt64) -> MEGAChatStatus {
        userStatus[userHandle] ?? .invalid
    }
    
    public override func userEmail(byUserHandle userHandle: UInt64, delegate: any MEGAChatRequestDelegate) {
        delegate.onChatRequestFinish?(self, request: chatRequest, error: MockChatError(chatErrorType: chatError))
    }
    
    public override func createChatLink(_ chatId: UInt64, delegate: any MEGAChatRequestDelegate) {
        delegate.onChatRequestFinish?(self, request: chatRequest, error: MockChatError(chatErrorType: chatError))
    }
    
    public override func queryChatLink(_ chatId: UInt64, delegate: any MEGAChatRequestDelegate) {
        delegate.onChatRequestFinish?(self, request: chatRequest, error: MockChatError(chatErrorType: chatError))
    }
}
