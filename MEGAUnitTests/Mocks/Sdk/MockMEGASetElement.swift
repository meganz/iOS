import Foundation
@testable import MEGA
import MEGADomain

final class MockMEGASetElement: MEGASetElement {
    private let setElementHandle: HandleEntity
    private let setElementOrder: HandleEntity
    private let setElementNodeId: HandleEntity
    private let setElementName: String
    private let setElementChangeType: MEGASetElementChangeType
    
    private var setElementModificationTime: Date?
    
    override var timestamp: Date { setElementModificationTime ?? Date() }
    
    init(handle: HandleEntity,
         order: HandleEntity,
         nodeId: HandleEntity,
         name: String = "",
         changeType: MEGASetElementChangeType = .new,
         modificationTime: Date? = nil) {
        setElementHandle = handle
        setElementOrder = order
        setElementNodeId = nodeId
        setElementName = name
        setElementChangeType = changeType
        
        setElementModificationTime = modificationTime
        
        super.init()
    }
}
