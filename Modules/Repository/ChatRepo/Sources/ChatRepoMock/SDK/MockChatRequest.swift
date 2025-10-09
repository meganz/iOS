import ChatRepo
import MEGAChatSdk

public final class MockChatRequest: MEGAChatRequest, @unchecked Sendable {
    
    private let _chatHandle: UInt64
    private let _privilege: Int
    private let _flag: Bool
    private let _text: String?
    
    public init(
        chatHandle: UInt64 = 1,
        privilege: Int = -2,
        flag: Bool = false,
        text: String? = nil
    ) {
        _chatHandle = chatHandle
        _privilege = privilege
        _flag = flag
        _text = text
        super.init()
    }
    
    public override var chatHandle: UInt64 {
        _chatHandle
    }
    
    public override var privilege: Int {
        _privilege
    }
    
    public override var isFlag: Bool {
        _flag
    }
    
    public override var text: String? {
        _text
    }
}
