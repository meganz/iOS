import Foundation
import MEGADomain
import MEGASdk

public struct NodeTagsRepository: NodeTagsRepositoryProtocol {

    public static var newRepo: NodeTagsRepository {
        NodeTagsRepository()
    }

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

    public func getTags(for node: NodeEntity) async -> [String]? {
        await sdk.node(for: node.handle)?.toNodeEntity().tags
    }

    public func add(tag: String, to node: NodeEntity) async throws {
        guard let node = await sdk.node(for: node.handle) else { throw NodeTagsUpdateError.nodeNotFound }
        return try await withCheckedThrowingContinuation { continuation in
            sdk.addTag(tag, to: node, delegate: RequestDelegate { result in
                continuation.resume(
                    with: result
                        .map { _ in () }
                        .mapError {
                            switch $0.type {
                            case .apiEArgs:
                                NodeTagsUpdateError.invalidArguments
                            case .apiEExist:
                                NodeTagsUpdateError.alreadyExists
                            case .apiEBusinessPastDue:
                                NodeTagsUpdateError.businessPastDue
                            default:
                                NodeTagsUpdateError.generic
                            }
                        }
                )
            })
        }
    }

    public func remove(tag: String, from node: NodeEntity) async throws {
        guard let node = await sdk.node(for: node.handle) else { throw NodeTagsUpdateError.nodeNotFound }
        return try await withCheckedThrowingContinuation { continuation in
            sdk.removeTag(tag, from: node, delegate: RequestDelegate { result in
                continuation.resume(
                    with: result
                        .map({ _ in () })
                        .mapError {
                            switch $0.type {
                            case .apiEArgs:
                                NodeTagsUpdateError.invalidArguments
                            case .apiENoent:
                                NodeTagsUpdateError.doesNotExist
                            case .apiEBusinessPastDue:
                                NodeTagsUpdateError.businessPastDue
                            default:
                                NodeTagsUpdateError.generic
                            }
                        }
                )
            })
        }
    }
}
