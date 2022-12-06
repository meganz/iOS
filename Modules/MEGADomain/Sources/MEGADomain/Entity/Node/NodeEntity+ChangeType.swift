import Foundation
import MEGASwift

public extension Sequence where Element == NodeEntity {
    func removedChangeTypeNodes() -> [NodeEntity] {
        nodes(for: [.removed, .parent])
    }
    
    func nodes(for changedTypes: ChangeTypeEntity) -> [NodeEntity] {
        filter { $0.changeTypes.intersection(changedTypes).isNotEmpty }
    }
    
    func containsNewNode() -> Bool {
        contains { $0.changeTypes.contains(.new) }
    }
    
    func hasModifiedAttributes() -> Bool {
        contains { $0.changeTypes.contains(.attributes) }
    }
    
    func hasModifiedParent() -> Bool {
        contains { $0.changeTypes.contains(.parent) }
    }
}
