import Foundation
import MEGADomain

struct NodeSearchRepository {
    
    struct Parameter {
        let searchText: String
        let nodeFormat: MEGANodeFormatType
        let sortOrder: MEGASortOrderType?
        let rootNodeHandle: HandleEntity?
        let completion: ([NodeEntity]) -> Void
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
                    parameter.completion([])
                    return {}
                }

                let cancelToken = MEGACancelToken()

                let searchOperation = SearchOperation(
                    parentNode: rootNode,
                    text: parameter.searchText,
                    cancelToken: cancelToken,
                    sortOrderType: parameter.sortOrder ?? .creationAsc,
                    nodeFormatType: parameter.nodeFormat,
                    sdk: sdk
                ) { (foundNodes, _) -> Void in
                    guard let foundNodes = foundNodes else {
                        parameter.completion([])
                        return
                    }
                    let sdkNodes = foundNodes.toNodeEntities()
                    parameter.completion(sdkNodes)
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
