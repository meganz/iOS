import MEGASdk

public final class MockDateSection: MEGADateSection, @unchecked Sendable {
    private let _groupId: String?
    private let _startDate: Int64
    private let _endDate: Int64
    private let _count: Int64

    public init(
        groupId: String?,
        startDate: Int64,
        endDate: Int64,
        count: Int64
    ) {
        _groupId = groupId
        _startDate = startDate
        _endDate = endDate
        _count = count
        super.init()
    }

    public override var groupId: String? { _groupId }
    public override var startDate: Int64 { _startDate }
    public override var endDate: Int64 { _endDate }
    public override var count: Int64 { _count }
}
