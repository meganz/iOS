import Foundation
import MEGADomain

struct NodeSearchRepository {
    
    struct Parameter {
        let searchText: String
        let recursive: Bool
        let nodeType: MEGANodeType
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

                // When we are applying nodeType we can not at the same time apply category, otherwise, sdk crashes
                let nodeFormat: MEGANodeFormatType = parameter.nodeType == .folder ? .unknown : parameter.nodeFormat

                let searchOperation = SearchWithFilterOperation(
                    sdk: sdk,
                    filter: .init(
                        term: parameter.searchText,
                        parentNodeHandle: rootNode.handle,
                        nodeType: Int32(parameter.nodeType.rawValue),
                        category: Int32(nodeFormat.rawValue),
                        sensitivity: false,
                        timeFrame: nil
                    ),
                    recursive: parameter.recursive,
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
