import Foundation

typealias MEGAGlobalOnNodesUpdateCompletion = (_ nodeList: MEGANodeList?) -> Void

class GlobalDelegate: NSObject, MEGAGlobalDelegate {
    let onNodesUpdateCompletion: MEGAGlobalOnNodesUpdateCompletion?
    
    @objc init(onNodesUpdateCompletion: @escaping MEGAGlobalOnNodesUpdateCompletion) {
        self.onNodesUpdateCompletion = onNodesUpdateCompletion
    }
    
    func onNodesUpdate(_ api: MEGASdk, nodeList: MEGANodeList?) {
        onNodesUpdateCompletion?(nodeList)
    }
}
