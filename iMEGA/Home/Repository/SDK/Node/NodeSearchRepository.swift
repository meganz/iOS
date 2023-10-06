import Foundation
import MEGADomain

struct NodeSearchRepository {
    
    struct Parameter {
        let searchText: String
        let nodeFormat: MEGANodeFormatType
        let sortOrder: MEGASortOrderType?
        let rootNodeHandle: HandleEntity?
        let completion: (MEGANodeList?) -> Void
    }

    var search: (
        _ parameters: Parameter
    ) -> () -> Void

    var cancel: (() -> Void) -> Void
}

extension NodeSearchRepository {

    static var live: Self {
        let sdk  = MEGASdk.shared

        let searchQueue = OperationQueue()
        searchQueue.name = "searchQueue"
        searchQueue.qualityOfService = .userInteractive
        
        return Self(
            search: { (parameter: NodeSearchRepository.Parameter) -> () -> Void in
                let searchRootNode: MEGANode?
                if let handle = parameter.rootNodeHandle {
                    searchRootNode = sdk.node(forHandle: handle)
                } else {
                    searchRootNode = sdk.rootNode
                }

                guard let rootNode = searchRootNode else {
                    parameter.completion(nil)
                    return {}
                }

                let cancelToken = MEGACancelToken()

                let searchOperation = SearchOperation(
                    sdk: sdk, 
                    parentNode: rootNode,
                    text: parameter.searchText,
                    nodeFormat: parameter.nodeFormat,
                    sortOrder: parameter.sortOrder ?? .creationAsc,
                    cancelToken: cancelToken
                ) { (nodeList, _) -> Void in
                    guard let nodeList else {
                        parameter.completion(nil)
                        return
                    }
                    parameter.completion(nodeList)
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
