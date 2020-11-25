import Foundation

typealias NodeHandle = UInt64

extension UInt64 {
    func validNode(in sdk: MEGASdk) -> MEGANode? {
        guard let node = sdk.node(forHandle: self), !sdk.isNode(inRubbish: node) else {
            return nil
        }
        
        return node
    }
}
