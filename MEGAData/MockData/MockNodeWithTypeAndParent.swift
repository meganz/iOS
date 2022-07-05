import Foundation

final class MockNodeWithTypeAndParent: MEGANode {
    enum NodeType {
        case file
        case folder
        case image
        case video
    }
    
    private let nodeType: NodeType
    private let _name: String
    private let _handle: MEGAHandle
    private let _parentHandle: MEGAHandle
    
    override var name: String! {
        _name
    }
    
    override var parentHandle: MEGAHandle {
        _parentHandle
    }
    
    override var handle: MEGAHandle {
        _handle
    }
    
    init(name: String, nodeType: NodeType = .file, handle: MEGAHandle = 0, parentHandle: MEGAHandle = 0) {
        self.nodeType = nodeType
        
        _name = name
        _handle = handle
        _parentHandle = parentHandle
        
        super.init()
    }
    
    override func isFile() -> Bool {
        nodeType == .file
    }
    
    override func isFolder() -> Bool {
        nodeType == .folder
    }
    
    override func getChanges() -> MEGANodeChangeType {
        .new
    }
}
