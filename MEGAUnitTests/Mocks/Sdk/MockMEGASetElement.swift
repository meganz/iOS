import Foundation
@testable import MEGA
import MEGADomain

final class MockMEGASetElement: MEGASetElement {
    private let setElementHandle: HandleEntity
    private let setElementOwnerId: HandleEntity
    private let setElementOrder: UInt64
    private let setElementNodeId: HandleEntity
    private let setElementName: String
    private let setElementChangeType: MEGASetElementChangeType
    private let setElementModificationTime: Date
    
    override var handle: HandleEntity { setElementHandle }
    override var ownerId: UInt64 { setElementOwnerId }
    override var order: UInt64 { setElementOrder }
    override var nodeId: UInt64 { setElementNodeId }
    override var name: String { setElementName }
    override var timestamp: Date { setElementModificationTime }
    
    init(handle: HandleEntity,
         ownerId: HandleEntity,
         order: UInt64,
         nodeId: HandleEntity,
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
