import Foundation
import MEGADomain
import MEGASdk
import MEGASDKRepo

public struct MockNodeAccess: NodeAccessProtocol {
    
    private let result: Result<MEGANode, any Error>
    
    public init(result: Result<MEGANode, any Error> = .failure(GenericErrorEntity())) {
        self.result = result
    }
    
    public func loadNode(completion: NodeLoadCompletion?) {
        
        switch result {
        case .success(let node):
            completion?(node, nil)
        case .failure(let error):
            completion?(nil, error)
        }
    }
    
    public func isTargetNode(for node: NodeEntity) -> Bool {
        switch result {
        case .success(let successNode):
            node.handle == successNode.handle
        case .failure:
            false
        }
    }
}
