import MEGADomain

@MainActor
public final class MockNodeTagsUseCase: NodeTagsUseCaseProtocol {
    public enum TagOperation: Equatable {
        case add(String)
        case remove(String)
    }
    public var _searchTags: [String]?
    public var _getTags: [String]?
    public private(set) var searchTexts: [String?] = []
    public private(set) var continuation: CheckedContinuation<[String]?, Never>?
    public private(set) var tagOperations: [TagOperation]  = []

    public init(searchTags: [String]? = nil, getTags: [String]? = nil) {
        _searchTags = searchTags
        _getTags = getTags
    }

    public func searchTags(for searchText: String?) async -> [String]? {
        searchTexts.append(searchText)
        if let _searchTags {
            return _searchTags
        }
        return await withTaskCancellationHandler {
            await withCheckedContinuation { continuation in
                if Task.isCancelled {
                    continuation.resume(returning: nil)
                } else {
                    self.continuation = continuation
                }
            }
        } onCancel: { [weak self] in
            Task { @MainActor [weak self] in
                let pending = self?.continuation
                self?.continuation = nil
                pending?.resume(returning: nil)
            }
        }
    }

    public func getTags(for node: NodeEntity) async -> [String]? {
        _getTags
    }

    public func add(tag: String, to node: NodeEntity) async throws {
        tagOperations.append(.add(tag))
    }

    public func remove(tag: String, from node: NodeEntity) async throws {
        tagOperations.append(.remove(tag))
    }
}
