import Foundation

extension MEGANode {
    
    /// Check whether the receiver is a child node of a given node or equal to that node.
    /// - Parameters:
    ///   - node: The `MEGANode` to check against the receiver.
    ///   - sdk: `MEGASdk` instance which manages both the receiver and the given node.
    /// - Returns: true if the receiver is an immediate or distant child node of the passed node or if passed node is equal to the receiver; otherwise false.
    @objc func isDescendant(of node: MEGANode, in sdk: MEGASdk) -> Bool {
        guard node.handle != handle else {
            return true
        }
        
        guard let parent = sdk.parentNode(for: self) else {
            return false
        }
        
        if parent.handle == node.handle {
            return true
        } else {
            return parent.isDescendant(of: node, in: sdk)
        }
    }
}
