import MEGASdk

public final class MockMEGASet: MEGASet {
    private let setHandle: MEGAHandle
    private let setUserId: MEGAHandle
    private let setCoverId: MEGAHandle
    private let setName: String
    private let setChangeType: MEGASetChangeType
    private var setModificationTime: Date
    
    public override var handle: UInt64 { setHandle }
    public override var userId: UInt64 { setUserId }
    public override var cover: UInt64 { setCoverId }
    public override var name: String? { setName }
    public override var timestamp: Date { setModificationTime }
    
    public init(handle: MEGAHandle,
                userId: MEGAHandle,
                coverId: MEGAHandle,
                name: String = "",
                changeType: MEGASetChangeType = .new,
                modificationTime: Date = Date()) {
        setHandle = handle
        setUserId = userId
        setCoverId = coverId
        setName = name
        setChangeType = changeType
        setModificationTime = modificationTime
        
        super.init()
    }
}
