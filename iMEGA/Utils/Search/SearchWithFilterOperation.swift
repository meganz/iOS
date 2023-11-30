class SearchWithFilterOperation: MEGAOperation {
    let sdk: MEGASdk
    let filter: MEGASearchFilter
    let recursive: Bool
    let sortOrder: MEGASortOrderType
    let cancelToken: MEGACancelToken

    let completion: (_ results: MEGANodeList?, _ isCanceled: Bool) -> Void

    @objc init(
        sdk: MEGASdk,
        filter: MEGASearchFilter,
        recursive: Bool,
        sortOrder: MEGASortOrderType,
        cancelToken: MEGACancelToken,
        completion: @escaping (_ results: MEGANodeList?, _ isCanceled: Bool) -> Void
    ) {
        self.sdk = sdk
        self.filter = filter
        self.recursive = recursive
        self.sortOrder = sortOrder
        self.cancelToken = cancelToken
        self.completion = completion
    }

    override func start() {
        startExecuting()
        let nodeList = sdk.search(
            with: filter,
            orderType: sortOrder,
            cancelToken: cancelToken
        )

        guard !isCancelled else {
            completion(nil, true)
            return
        }

        completion(nodeList, false)
        finish()
    }
}
