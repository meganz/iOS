import Foundation
import MEGADomain
import MEGASdk

public struct NodeTagsRepository: NodeTagsRepositoryProtocol {
    private let sdk: MEGASdk

    public init(sdk: MEGASdk = .sharedSdk) {
        self.sdk = sdk
    }

    public func searchTags(for searchText: String?) async -> [String]? {
        let cancelToken = ThreadSafeCancelToken()
        return await withTaskCancellationHandler {
            guard !cancelToken.value.isCancelled else { return nil }
            return sdk.nodeTags(forSearch: searchText, cancelToken: cancelToken.value)
        } onCancel: {
            if !cancelToken.value.isCancelled {
                cancelToken.value.cancel()
            }
        }
    }
}
