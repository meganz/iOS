import ChatRepo
import MEGAChatSdk

public final class MockChatRequest: MEGAChatRequest {
    
    private let _chatHandle: UInt64
    private let _privilege: Int
    
    public init(
        chatHandle: UInt64 = 1,
        privilege: Int = -2
    ) {
        _chatHandle = chatHandle
        _privilege = privilege
        super.init()
    }
    
    public override var chatHandle: UInt64 {
        _chatHandle
    }
    
    public override var privilege: Int {
        _privilege
    }
}
