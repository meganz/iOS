class SearchOperation: MEGAOperation {
    let sdk: MEGASdk
    let parentNode: MEGANode
    let text: String
    let recursive: Bool
    let nodeFormat: MEGANodeFormatType
    let sortOrder: MEGASortOrderType
    let cancelToken: MEGACancelToken

    let completion: (_ results: MEGANodeList?, _ isCanceled: Bool) -> Void

    @objc init(
        sdk: MEGASdk,
        parentNode: MEGANode,
        text: String,
        recursive: Bool,
        nodeFormat: MEGANodeFormatType,
        sortOrder: MEGASortOrderType,
        cancelToken: MEGACancelToken,
        completion: @escaping (_ results: MEGANodeList?, _ isCanceled: Bool) -> Void
    ) {
        self.sdk = sdk
        self.parentNode = parentNode
        self.text = text
        self.recursive = recursive
        self.nodeFormat = nodeFormat
        self.sortOrder = sortOrder
        self.cancelToken = cancelToken
        self.completion = completion
    }

    override func start() {
        startExecuting()
        let nodeList = sdk.nodeListSearch(
            for: parentNode,
            search: text,
            cancelToken: cancelToken,
            recursive: recursive,
            orderType: sortOrder,
            nodeFormatType: nodeFormat,
            folderTargetType: .all
        )

        guard !isCancelled else {
            completion(nil, true)
            return
        }

        completion(nodeList, false)
        finish()
    }
}
