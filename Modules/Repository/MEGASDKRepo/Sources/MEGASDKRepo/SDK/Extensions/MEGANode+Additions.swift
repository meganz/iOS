import MEGASdk

public extension MEGANode {
    
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
    
    /// Check whether the receiver is a child node of an unverified shared folder node.
    /// - Parameters:
    ///   - email: The email of the receiver's owner.
    ///   - sdk: `MEGASdk` instance which manages receiver's owner.
    /// - Returns: true if the node's `isNodeKeyDecrypted` is false and user has not yet verified the owner; otherwise false.
    @objc func isUndecrypted(ownerEmail email: String, in sdk: MEGASdk) -> Bool {
        guard let owner = sdk.contact(forEmail: email),
              !self.isNodeKeyDecrypted() else {
            return false
        }
        return !sdk.areCredentialsVerified(of: owner)
    }
    
    @objc func mnz_renameNode(_ newName: String, completion: ((MEGARequest) -> Void)?) {
        MEGASdk.sharedSdk.renameNode(
            self,
            newName: newName,
            delegate: RequestDelegate(completion: { result in
                switch result {
                case .success(let request):
                    completion?(request)
                case .failure:
                    break
                }
            })
        )
    }
}
