import Foundation
@testable import MEGA

final class MockNode: MEGANode {
    private let nodeType: MEGANodeType
    private let nodeName: String
    private let nodeParentHandle: MEGAHandle
    private let nodeHandle: MEGAHandle
    private let changeType: MEGANodeChangeType
    private var nodeModificationTime: Date?
    
    init(handle: MEGAHandle,
         name: String = "",
         nodeType: MEGANodeType = .file,
         parentHandle: MEGAHandle = .invalid,
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
    
    override var handle: MEGAHandle { nodeHandle }
    
    override var type: MEGANodeType { nodeType }
    
    override func getChanges() -> MEGANodeChangeType { changeType }
    
    override func hasChangedType(_ changeType: MEGANodeChangeType) -> Bool {
        self.changeType.rawValue & changeType.rawValue > 0
    }
    
    override func isFile() -> Bool { nodeType == .file }
    
    override func isFolder() -> Bool { nodeType == .folder }
    
    override var name: String! { nodeName }
    
    override var parentHandle: MEGAHandle { nodeParentHandle }
    
    override var modificationTime: Date? { nodeModificationTime }
}
