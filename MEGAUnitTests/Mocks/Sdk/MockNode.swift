import Foundation
@testable import MEGA
import MEGADomain

final class MockNode: MEGANode {
    private let nodeType: MEGANodeType
    private let nodeName: String
    private let nodeParentHandle: HandleEntity
    private let nodeHandle: HandleEntity
    private let changeType: MEGANodeChangeType
    private var nodeModificationTime: Date?
    
    init(handle: HandleEntity,
         name: String = "",
         nodeType: MEGANodeType = .file,
         parentHandle: HandleEntity = .invalid,
         changeType: MEGANodeChangeType = .new,
         modificationTime: Date? = nil ) {
        nodeHandle = handle
        nodeName = name
        self.nodeType = nodeType
        nodeParentHandle = parentHandle
        self.changeType = changeType
        nodeModificationTime = modificationTime
        super.init()
    }
    
    override var handle: HandleEntity { nodeHandle }
    
    override var type: MEGANodeType { nodeType }
    
    override func getChanges() -> MEGANodeChangeType { changeType }
    
    override func hasChangedType(_ changeType: MEGANodeChangeType) -> Bool {
        self.changeType.rawValue & changeType.rawValue > 0
    }
    
    override func isFile() -> Bool { nodeType == .file }
    
    override func isFolder() -> Bool { nodeType == .folder }
    
    override var name: String! { nodeName }
    
    override var parentHandle: HandleEntity { nodeParentHandle }
    
    override var modificationTime: Date? { nodeModificationTime }
}
