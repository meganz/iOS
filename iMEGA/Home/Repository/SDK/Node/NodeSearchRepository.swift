import Foundation

struct NodeSearchRepository {

    var search: (
        _ filename: String,
        _ rootNodeHandle: MEGAHandle?,
        _ completion: (@escaping ([SDKNode]) -> Void)
    ) -> () -> Void

    var cancel: (() -> Void) -> Void
}

extension NodeSearchRepository {

    static var live: Self {
        let sdk  = MEGASdkManager.sharedMEGASdk()

        let searchQueue = OperationQueue()
        searchQueue.name = "searchQueue"
        searchQueue.qualityOfService = .userInteractive
        
        return Self(
            search: { (searchText, nodeHandle, completionAction) in
                let searchRootNode = nodeHandle == nil ? sdk.rootNode : sdk.node(forHandle: nodeHandle!)

                guard let rootNode = searchRootNode else {
                    completionAction([])
                    return {}
                }

                let cancelToken = MEGACancelToken()

                let searchOperation = SearchOperation(
                    parentNode: rootNode,
                    text: searchText,
                    cancelToken: cancelToken
                ) { foundNodes, _ in
                    guard let foundNodes = foundNodes else {
                        completionAction([])
                        return
                    }
                    let sdkNodes = foundNodes.map { node in
                        SDKNode(with: node)
                    }
                    completionAction(sdkNodes)
                }

                searchQueue.addOperation(searchOperation)
                return {
                    cancelToken.cancel(withNewValue: true)
                }
            },

            cancel: { cancelAction in
                cancelAction()
            }
        )
    }
}
