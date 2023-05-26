import MEGASdk

public final class MockUserAlert: MEGAUserAlert {
    
    private let _seen: Bool
    private let _relevant: Bool
    
    public init(
        isSeen: Bool = .random(),
        isRelevant: Bool = .random()
    ) {
        _seen = isSeen
        _relevant = isRelevant
    }
    
    public override var isSeen: Bool { _seen }
    
    public override var isRelevant: Bool { _relevant }
}
