import Foundation
import MEGADomain

struct NodeSearchRepository {

    var search: (
        _ filename: String,
        _ rootNodeHandle: HandleEntity?,
        _ completion: (@escaping ([NodeEntity]) -> Void)
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
            search: { (searchText: String, nodeHandle: HandleEntity?, completionAction: (@escaping ([NodeEntity]) -> Void)) -> () -> Void in
                let searchRootNode: MEGANode?
                if let handle = nodeHandle {
                    searchRootNode = sdk.node(forHandle: handle)
                } else {
                    searchRootNode = sdk.rootNode
                }

                guard let rootNode = searchRootNode else {
                    completionAction([])
                    return {}
                }

                let cancelToken = MEGACancelToken()

                let searchOperation = SearchOperation(
                    parentNode: rootNode,
                    text: searchText,
                    cancelToken: cancelToken
                ) { (foundNodes, _) -> Void in
                    guard let foundNodes = foundNodes else {
                        completionAction([])
                        return
                    }
                    let sdkNodes = foundNodes.toNodeEntities()
                    completionAction(sdkNodes)
                }

                searchQueue.addOperation(searchOperation)
                return {
                    cancelToken.cancel()
                }
            },

            cancel: { cancelAction -> Void in
                cancelAction()
            }
        )
    }
}
