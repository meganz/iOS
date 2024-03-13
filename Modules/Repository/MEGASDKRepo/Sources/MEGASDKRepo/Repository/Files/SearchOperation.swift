// We should move completely to using SearchOperationWithFilter globally in the app as a part of https://jira.developers.mega.co.nz/browse/FM-1488
import MEGAFoundation
import MEGASdk

public final class SearchOperation: AsyncOperation {
    let sdk: MEGASdk
    let parentNode: MEGANode
    let text: String
    let recursive: Bool
    let nodeFormat: MEGANodeFormatType
    let sortOrder: MEGASortOrderType
    let cancelToken: MEGACancelToken

    let completion: (_ results: MEGANodeList?, _ isCanceled: Bool) -> Void

    @objc public init(
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

    override public func start() {
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
        finishOperation()
    }
}
