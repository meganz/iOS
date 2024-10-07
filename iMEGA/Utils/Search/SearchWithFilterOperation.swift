class SearchWithFilterOperation: Operation, @unchecked Sendable {
    let sdk: MEGASdk
    let filter: MEGASearchFilter
    let page: MEGASearchPage?
    let recursive: Bool
    let sortOrder: MEGASortOrderType
    let cancelToken: MEGACancelToken

    let completion: (_ results: MEGANodeList?, _ isCanceled: Bool) -> Void

    private var isOperationCancelled: Bool {
        dependencies.contains(where: \.isCancelled) || isCancelled
    }

    @objc init(
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

    override func main() {
        guard !isOperationCancelled else {
            completion(nil, true)
            return
        }

        let nodeList = sdk.search(
            with: filter,
            orderType: sortOrder,
            page: page,
            cancelToken: cancelToken
        )

        completion(nodeList, isOperationCancelled)
    }
}
