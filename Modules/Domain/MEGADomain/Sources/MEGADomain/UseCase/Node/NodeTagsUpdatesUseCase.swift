import AsyncAlgorithms
import Foundation
import MEGASwift

/// Tags updates related to a certain node
public enum TagsUpdatesEntity: Sendable, Equatable {
    /// Signaling an update in a node's tags or the account's tags
    case tagsUpdated(node: NodeEntity)

    /// Signaling that a node's tags are no longer valid.
    /// Some examples:
    ///  - When a node is moved to rubbish bin, its tags are no longer valid
    ///  - When a node is removed from CD (e.g: removed from rubbish bin or move to `incoming shared`, its tags are no longer valid
    case tagsInvalidated(node: NodeEntity)
}

public protocol NodeTagsUpdatesUseCaseProtocol: Sendable {
    func tagsUpdates(for node: NodeEntity) -> AnyAsyncSequence<TagsUpdatesEntity>
}

public struct NodeTagsUpdatesUseCase: NodeTagsUpdatesUseCaseProtocol {
    private let nodeRepository: any NodeRepositoryProtocol
    private let nodeTagsRepository: any NodeTagsRepositoryProtocol

    public init(
        nodeRepository: some NodeRepositoryProtocol,
        nodeTagsRepository: some NodeTagsRepositoryProtocol
    ) {
        self.nodeRepository = nodeRepository
        self.nodeTagsRepository = nodeTagsRepository
    }

    public func tagsUpdates(for node: NodeEntity) -> AnyAsyncSequence<TagsUpdatesEntity> {
        merge(
            nodeTagsUpdates(for: node),
            allTagsUpdates(excluding: node)
        ).eraseToAnyAsyncSequence()
    }

    private func allTagsUpdates(excluding node: NodeEntity) -> AnyAsyncSequence<TagsUpdatesEntity> {
        nodeRepository
            .nodeUpdates
            .compactMap { updatedNodes -> [String]? in
                if updatedNodes.first(where: { $0.handle == node.handle }) != nil { return nil }
                let possibleNodeUpdates = updatedNodes.first(where: {
                    // If a node is removed and it contains tags, it might cause account's tags to change
                    return $0.changeTypes.contains(.removed) && $0.tags.isNotEmpty
                    // If a node has changes in its tags, it might cause account's tags to change
                    || $0.changeTypes.contains(.tags)
                })
                guard possibleNodeUpdates != nil else { return nil }
                return await self.nodeTagsRepository.searchTags(for: "") ?? []
            }
            .removeDuplicates()
            .map { _ in
                return TagsUpdatesEntity.tagsUpdated(node: node)
            }
            .eraseToAnyAsyncSequence()
    }

    private func nodeTagsUpdates(for node: NodeEntity) -> AnyAsyncSequence<TagsUpdatesEntity> {
        nodeRepository
            .nodeUpdates
            .compactMap { updatedNodes -> TagsUpdatesEntity? in
                guard let updatedNode = updatedNodes.first(where: { $0.handle == node.handle }) else {
                    return nil
                }
                if updatedNode.changeTypes.contains(.removed) || self.nodeRepository.isInRubbishBin(node: updatedNode) {
                    return TagsUpdatesEntity.tagsInvalidated(node: updatedNode)
                } else if updatedNode.changeTypes.contains(.tags) {
                    return TagsUpdatesEntity.tagsUpdated(node: updatedNode)
                } else {
                    return nil
                }
            }
            .eraseToAnyAsyncSequence()
    }
}
