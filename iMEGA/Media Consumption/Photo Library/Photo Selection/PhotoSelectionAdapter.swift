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
        if #available(iOS 14.0, *) {
            return nodeEntities.count
        } else {
            return megaNodes.count
        }
    }
    
    @objc var isEmpty: Bool {
        if #available(iOS 14.0, *) {
            return nodeEntities.isEmpty
        } else {
            return megaNodes.isEmpty
        }
    }
    
    @objc var nodes: [MEGANode] {
        if #available(iOS 14.0, *) {
            return nodeEntities.values.compactMap { $0.toMEGANode(in: self.sdk) }
        } else {
            return Array(megaNodes.values)
        }
    }
    
    @objc subscript(handle: HandleEntity) -> MEGANode? {
        get {
            if #available(iOS 14.0, *) {
                return nodeEntities[handle]?.toMEGANode(in: self.sdk)
            } else {
                return megaNodes[handle]
            }
        }
        set {
            if #available(iOS 14.0, *) {
                nodeEntities[handle] = newValue?.toNodeEntity()
            } else {
                megaNodes[handle] = newValue
            }
        }
    }
    
    @objc func removeAll() {
        if #available(iOS 14.0, *) {
            nodeEntities.removeAll()
        } else {
            megaNodes.removeAll()
        }
    }
    
    @objc func removeNode(by handle: HandleEntity) {
        if #available(iOS 14.0, *) {
            nodeEntities[handle] = nil
        } else {
            megaNodes[handle] = nil
        }
    }
    
    func setSelectedNodes(_ nodes: [NodeEntity]) {
        nodeEntities = Dictionary(uniqueKeysWithValues: nodes.map { ($0.handle, $0) })
    }
    
    @objc func setSelectedNodes(_ nodes: [MEGANode]) {
        megaNodes = Dictionary<HandleEntity, MEGANode>(uniqueKeysWithValues: nodes.map { ($0.handle, $0) })
    }
}
