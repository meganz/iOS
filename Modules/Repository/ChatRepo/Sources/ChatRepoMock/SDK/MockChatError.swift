import MEGAChatSdk

public final class MockChatError: MEGAChatError {
    
    private let megaChatErrorType: MEGAChatErrorType
    
    public init(
        chatErrorType: MEGAChatErrorType = .MEGAChatErrorTypeOk
    ) {
        megaChatErrorType = chatErrorType
    }
    
    public override var type: MEGAChatErrorType {
        megaChatErrorType
    }
}
