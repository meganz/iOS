import MEGAFoundation
import MEGASdk

final class SearchWithFilterOperation: AsyncOperation, @unchecked Sendable {
    let sdk: MEGASdk
    let filter: MEGASearchFilter
    let page: MEGASearchPage?
    let recursive: Bool
    let sortOrder: MEGASortOrderType
    let cancelToken: ThreadSafeCancelToken

    let completion: (_ results: MEGANodeList?, _ isCanceled: Bool) -> Void

    init(
        sdk: MEGASdk,
        filter: MEGASearchFilter,
        page: MEGASearchPage?,
        recursive: Bool,
        sortOrder: MEGASortOrderType,
        cancelToken: ThreadSafeCancelToken,
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
            sdk.search(with: filter, orderType: sortOrder, page: page, cancelToken: cancelToken.value)
        } else {
            sdk.searchNonRecursively(with: filter, orderType: sortOrder, page: page, cancelToken: cancelToken.value)
        }
        
        guard !isCancelled, !cancelToken.value.isCancelled else {
            completion(nil, true)
            return
        }

        completion(nodeList, false)
        finishOperation()
    }
    
    override func cancel() {
        
        guard !isCancelled else {
            return
        }
        
        if !cancelToken.value.isCancelled {
            cancelToken.value.cancel()
        }
        
        super.cancel()
    }
}
