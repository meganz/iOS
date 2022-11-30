import Foundation
import MEGADomain

@objc final class PhotoSelectionAdapter: NSObject {
    private var megaNodes = [HandleEntity: MEGANode]()
    private var nodeEntities = [HandleEntity: NodeEntity]()
    private let sdk: MEGASdk
    
    @objc init(sdk: MEGASdk) {
        self.sdk = sdk
    }
    
    @objc var count: Int {
        nodeEntities.count
    }
    
    @objc var isEmpty: Bool {
        nodeEntities.isEmpty
    }
    
    @objc var nodes: [MEGANode] {
        nodeEntities.values.compactMap { $0.toMEGANode(in: self.sdk) }
    }
    
    @objc subscript(handle: HandleEntity) -> MEGANode? {
        get {
            nodeEntities[handle]?.toMEGANode(in: self.sdk)
        }
        set {
            nodeEntities[handle] = newValue?.toNodeEntity()
        }
    }
    
    @objc func removeAll() {
        nodeEntities.removeAll()
    }
    
    @objc func removeNode(by handle: HandleEntity) {
        nodeEntities[handle] = nil
    }
    
    func setSelectedNodes(_ nodes: [NodeEntity]) {
        nodeEntities = Dictionary(uniqueKeysWithValues: nodes.map { ($0.handle, $0) })
    }
    
    @objc func setSelectedNodes(_ nodes: [MEGANode]) {
        megaNodes = Dictionary<HandleEntity, MEGANode>(uniqueKeysWithValues: nodes.map { ($0.handle, $0) })
    }
}
