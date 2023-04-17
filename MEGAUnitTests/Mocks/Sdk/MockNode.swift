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
    private let _hasThumbnail: Bool
    private let isNodeDecrypted: Bool
    private let isNodeExported: Bool
    private let videoDuration: Int
    let nodePath: String?
    
    init(handle: HandleEntity,
         name: String = "",
         nodeType: MEGANodeType = .file,
         parentHandle: HandleEntity = .invalid,
         changeType: MEGANodeChangeType = .new,
         modificationTime: Date? = nil,
         hasThumbnail: Bool = false,
         nodePath: String? = nil,
         isNodeDecrypted: Bool = false,
         isNodeExported: Bool = false,
         duration: Int = 0) {
        nodeHandle = handle
        nodeName = name
        self.nodeType = nodeType
        nodeParentHandle = parentHandle
        self.changeType = changeType
        nodeModificationTime = modificationTime
        _hasThumbnail = hasThumbnail
        self.nodePath = nodePath
        self.isNodeDecrypted = isNodeDecrypted
        self.isNodeExported = isNodeExported
        self.videoDuration = duration
        super.init()
    }
    
    override var handle: HandleEntity { nodeHandle }
    
    override var type: MEGANodeType { nodeType }
    
    override var duration: Int { videoDuration }
    
    override func getChanges() -> MEGANodeChangeType { changeType }
    
    override func hasChangedType(_ changeType: MEGANodeChangeType) -> Bool {
        self.changeType.rawValue & changeType.rawValue > 0
    }
    
    override func isFile() -> Bool { nodeType == .file }
    
    override func isFolder() -> Bool { nodeType == .folder }
    
    override var name: String! { nodeName }
    
    override var parentHandle: HandleEntity { nodeParentHandle }
    
    override var modificationTime: Date? { nodeModificationTime }
    
    override func hasThumbnail() -> Bool { _hasThumbnail }
    
    override func isExported() -> Bool { isNodeExported }
    
}
