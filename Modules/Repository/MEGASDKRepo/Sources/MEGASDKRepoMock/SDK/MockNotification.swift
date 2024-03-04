import MEGASdk

public final class MockNotification: MEGANotification {
    private let _identifier: UInt
    
    public init(identifier: UInt = 0) {
        _identifier = identifier
    }
    
    public override var identifier: UInt { _identifier }
}
