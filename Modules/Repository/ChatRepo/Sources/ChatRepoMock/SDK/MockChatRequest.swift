import ChatRepo
import MEGAChatSdk

public final class MockChatRequest: MEGAChatRequest {
    
    private let _chatHandle: UInt64
    
    public init(
        chatHandle: UInt64 = 1
    ) {
        _chatHandle = chatHandle
        super.init()
    }
    
    public override var chatHandle: UInt64 {
        _chatHandle
    }
}
