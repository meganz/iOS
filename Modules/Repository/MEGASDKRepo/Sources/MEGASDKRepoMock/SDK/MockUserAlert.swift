import MEGASdk

public final class MockUserAlert: MEGAUserAlert {
    private let _identifier: UInt
    private let _seen: Bool
    private let _relevant: Bool
    private let _type: MEGAUserAlertType
    
    public init(
        identifier: UInt = 0,
        isSeen: Bool = .random(),
        isRelevant: Bool = .random(),
        type: MEGAUserAlertType = .scheduledMeetingNew
    ) {
        _identifier = identifier
        _seen = isSeen
        _relevant = isRelevant
        _type = type
    }
    
    public override var identifier: UInt { _identifier }
    
    public override var isSeen: Bool { _seen }
    
    public override var isRelevant: Bool { _relevant }
    
    public override var type: MEGAUserAlertType { _type }
}
