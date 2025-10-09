import MEGAAppSDKRepo
import MEGASdk

public final class MockEvent: MEGAEvent, @unchecked Sendable {
    public let _type: Event
    public let _text: String?
    public let _number: Int
    public let _eventString: String?
    
    public init(type: Event, text: String? = nil, number: Int, eventString: String? = nil) {
        self._type = type
        self._text = text
        self._number = number
        self._eventString = eventString
    }
    
    public override var type: Event { _type }
    public override var text: String? { _text }
    public override var number: Int { _number }
    public override var eventString: String? { _eventString }
}
