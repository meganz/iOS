import MEGAData
import MEGASdk

public final class MockMEGASet: MEGASet {
    private let setHandle: MEGAHandle
    private let setUserId: MEGAHandle
    private let setCoverId: MEGAHandle
    private let setName: String
    private let setChangeType: MEGASetChangeType
    private var setModificationTime: Date
    private var setCreationTime: Date
    
    public override var handle: UInt64 { setHandle }
    public override var userId: UInt64 { setUserId }
    public override var cover: UInt64 { setCoverId }
    public override var name: String? { setName }
    public override var timestamp: Date { setModificationTime }
    public override var timestampCreated: Date { setCreationTime }
    
    public init(handle: MEGAHandle,
                userId: MEGAHandle = .invalidHandle,
                coverId: MEGAHandle = .invalidHandle,
                name: String = "",
                changeType: MEGASetChangeType = .new,
                creationTime: Date = Date(),
                modificationTime: Date = Date()) {
        setHandle = handle
        setUserId = userId
        setCoverId = coverId
        setName = name
        setChangeType = changeType
        setCreationTime = creationTime
        setModificationTime = modificationTime
        
        super.init()
    }
}
