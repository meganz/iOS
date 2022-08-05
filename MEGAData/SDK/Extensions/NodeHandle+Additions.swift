import Foundation
import MEGADomain

extension HandleEntity {
    func validNode(in sdk: MEGASdk) -> MEGANode? {
        guard let node = sdk.node(forHandle: self), !sdk.isNode(inRubbish: node) else {
            return nil
        }
        
        return node
    }
}
