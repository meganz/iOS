import MEGAFoundation
import MEGASdk

final class SearchWithFilterOperation: AsyncOperation {
    let sdk: MEGASdk
    let filter: MEGASearchFilter
    let page: MEGASearchPage?
    let recursive: Bool
    let sortOrder: MEGASortOrderType
    let cancelToken: MEGACancelToken

    let completion: (_ results: MEGANodeList?, _ isCanceled: Bool) -> Void

    init(
        sdk: MEGASdk,
        filter: MEGASearchFilter,
        page: MEGASearchPage?,
        recursive: Bool,
        sortOrder: MEGASortOrderType,
        cancelToken: MEGACancelToken,
        completion: @escaping (_ results: MEGANodeList?, _ isCanceled: Bool) -> Void
    ) {
        self.sdk = sdk
        self.filter = filter
        self.page = page
        self.recursive = recursive
        self.sortOrder = sortOrder
        self.cancelToken = cancelToken
        self.completion = completion
    }

    override func start() {
        startExecuting()
        
        let nodeList = if recursive {
            sdk.search(with: filter, orderType: sortOrder, page: page, cancelToken: cancelToken)
        } else {
            sdk.searchNonRecursively(with: filter, orderType: sortOrder, page: page, cancelToken: cancelToken)
        }
        
        guard !isCancelled, !cancelToken.isCancelled else {
            completion(nil, true)
            cancelOperation()
            return
        }

        completion(nodeList, false)
        finishOperation()
    }
    
    override func cancel() {
        
        guard !isCancelled else {
            return
        }
        
        super.cancel()
        
        if !cancelToken.isCancelled {
            cancelToken.cancel()
        }
        
        cancelOperation()
    }
}
