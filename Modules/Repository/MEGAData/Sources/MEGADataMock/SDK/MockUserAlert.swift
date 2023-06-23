import MEGASdk

public final class MockUserAlert: MEGAUserAlert {
    private let _identifier: UInt
    private let _seen: Bool
    private let _relevant: Bool
    
    public init(
        identifier: UInt = 0,
        isSeen: Bool = .random(),
        isRelevant: Bool = .random()
    ) {
        _identifier = identifier
        _seen = isSeen
        _relevant = isRelevant
    }
    
    public override var identifier: UInt { _identifier }
    
    public override var isSeen: Bool { _seen }
    
    public override var isRelevant: Bool { _relevant }
}
