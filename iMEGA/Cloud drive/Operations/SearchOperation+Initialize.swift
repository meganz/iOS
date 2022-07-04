import Foundation

extension SearchOperation {
    
    convenience init(parentNode node: MEGANode,
                     text: String,
                     cancelToken: MEGACancelToken,
                     sortOrderType: MEGASortOrderType,
                     nodeFormatType: MEGANodeFormatType,
                     completion: @escaping (Result<[MEGANode], Error>) -> Void) {
        self.init(
            parentNode: node,
            text: text,
            cancelToken: cancelToken,
            sortOrderType: sortOrderType,
            nodeFormatType: nodeFormatType
        ) { (foundNodes, isCancelled) -> Void in
            guard !isCancelled else {
                completion(.failure(NodeSearchResultErrorEntity.cancelled))
                return
            }
            
            completion(.success(foundNodes ?? []))
        }
    }
}
