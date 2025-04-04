import MEGAAppSDKRepo
import MEGASdk

public final class MockMEGASetElement: MEGASetElement, @unchecked Sendable {
    private let setElementHandle: MEGAHandle
    private let setElementOwnerId: MEGAHandle
    private let setElementOrder: UInt64
    private let setElementNodeId: MEGAHandle
    private let setElementName: String
    private let setElementChangeType: MEGASetElementChangeType
    private let setElementModificationTime: Date
    
    public override var handle: MEGAHandle { setElementHandle }
    public override var ownerId: UInt64 { setElementOwnerId }
    public override var order: UInt64 { setElementOrder }
    public override var nodeId: UInt64 { setElementNodeId }
    public override var name: String { setElementName }
    public override var timestamp: Date { setElementModificationTime }
    
    public init(handle: MEGAHandle,
                ownerId: MEGAHandle = .invalidHandle,
                order: UInt64 = 0,
                nodeId: MEGAHandle = .invalidHandle,
                name: String = "",
                changeType: MEGASetElementChangeType = .new,
                modificationTime: Date = Date()) {
        setElementHandle = handle
        setElementOwnerId = ownerId
        setElementOrder = order
        setElementNodeId = nodeId
        setElementName = name
        setElementChangeType = changeType
        setElementModificationTime = modificationTime
        
        super.init()
    }
}
