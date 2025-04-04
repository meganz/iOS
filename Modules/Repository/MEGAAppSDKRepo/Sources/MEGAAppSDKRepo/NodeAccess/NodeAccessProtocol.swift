import Foundation
import MEGADomain
import MEGASdk

public typealias NodeLoadCompletion = @Sendable (_ node: MEGANode?, _ error: (any Error)?) -> Void

public protocol NodeAccessProtocol: Sendable {
    /// Load the current type node, it follows the below steps to load the node:
    /// 1. If the handle in memory is valid, we return it
    /// 2. Otherwise, we try to load the node from server side
    /// 3. If the current type node is non-exist in server side, we create a new one and return it
    ///
    /// - Attention:
    /// Here we are using the double-checked locking approach to boost the performance. If the handle in memory is valid,
    /// we will return it straightaway without going through the synchronisation point. Double-checked locking anti-pattern
    /// is not a concern here, as handle is a primitive type and it is safe to enter the synchronisation point.
    ///
    /// - Parameter completion: A block that the node loader calls after the node load completes. It will be called on an arbitrary dispatch queue. Please dispatch to Main queue if need to update UI.
    func loadNode(completion: NodeLoadCompletion?)
    
    /// Check if a given node is the target folder or not
    ///
    /// - Attention:
    /// This method is not as accurate as `loadNode(:)` which will check if the current target node in memory is valid or not, and load it from server side if needed.
    /// This method `isTargetNode` simply check if the given node against the current target node in memory. There is a small gap that the target node
    /// in memory is not valid in some edge cases. If you need accurate target node, please use `loadNode(:)` method.
    ///
    /// - Parameter node: The given node to be checked
    /// - Returns: if the node is the target folder return true, otherwise return false
    func isTargetNode(for node: NodeEntity) -> Bool
}
