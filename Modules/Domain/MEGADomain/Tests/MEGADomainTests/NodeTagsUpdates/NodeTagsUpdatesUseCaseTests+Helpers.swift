import MEGADomain
import MEGADomainMock
import MEGASwift
import Testing

// Helper classes and methods to cater for NodeTagsUpdatesUseCaseTests
extension NodeTagsUpdatesUseCaseTests {
    enum Helper {
        static let targetNodeHandle: UInt64 = 1
        static let targetNode = NodeEntity(handle: targetNodeHandle)
        static func makeSut() -> (NodeTagsUpdatesUseCase, MockNodeRepository, MockNodeTagsRepository) {
            let nodeRepo = MockNodeRepository()
            let nodeTagsUpdatesRepo = MockNodeTagsRepository.newRepo
            let sut = NodeTagsUpdatesUseCase(nodeRepository: nodeRepo, nodeTagsRepository: nodeTagsUpdatesRepo)
            return (sut, nodeRepo, nodeTagsUpdatesRepo)
        }
    }

    final class MockNodeRepository: NodeRepositoryProtocol, @unchecked Sendable {
        func simulateNodeUpdates(_ updatedNodes: [NodeEntity]) {
            nodeUpdatesContinuations.forEach {
                $0.yield(updatedNodes)
            }
        }

        private var nodeUpdatesContinuations = [AsyncStream<[NodeEntity]>.Continuation]()

        static var newRepo: MockNodeRepository {
            MockNodeRepository()
        }

        var nodeUpdates: AnyAsyncSequence<[NodeEntity]> {
            let (nodeUpdatesStream, continuation) = AsyncStream.makeStream(of: [NodeEntity].self)
            self.nodeUpdatesContinuations.append(continuation)
            return nodeUpdatesStream.eraseToAnyAsyncSequence()
        }
        
        var folderLinkNodeUpdates: AnyAsyncSequence<[NodeEntity]> {
            EmptyAsyncSequence().eraseToAnyAsyncSequence()
        }

        func nodeForHandle(_ handle: HandleEntity) -> NodeEntity? { nil }

        func nodeFor(fileLink: FileLinkEntity) async throws -> NodeEntity {
            .init()
        }

        func childNodeNamed(name: String, in parentHandle: HandleEntity) -> NodeEntity? {
            nil
        }

        func childNode(parent node: NodeEntity, name: String, type: NodeTypeEntity) async -> NodeEntity? {
            nil
        }

        func rubbishNode() -> NodeEntity? {
            nil
        }

        func rootNode() -> NodeEntity? {
            nil
        }

        func parents(of node: NodeEntity) async -> [NodeEntity] {
            []
        }

        func asyncChildren(of node: NodeEntity, sortOrder: SortOrderEntity) async -> NodeListEntity? {
            nil
        }

        func children(of node: NodeEntity) -> NodeListEntity? {
            nil
        }

        func childrenNames(of node: NodeEntity) -> [String]? {
            nil
        }

        var _isInRubbishBin = false
        func isInRubbishBin(node: NodeEntity) -> Bool {
            _isInRubbishBin
        }

        func createFolder(with name: String, in parent: NodeEntity) async throws -> NodeEntity {
            .init()
        }

        func isInheritingSensitivity(node: NodeEntity) async throws -> Bool {
            false
        }

        func isInheritingSensitivity(node: NodeEntity) throws -> Bool {
            false
        }

        func isNodeDecrypted(node: MEGADomain.NodeEntity) -> Bool { false }
    }
}

extension NodeTagsUpdatesUseCaseTests {
    struct Arguments: Sendable {
        struct Input {
            let updatedNode: NodeEntity
            let setupRepos: (@Sendable (MockNodeRepository, MockNodeTagsRepository) -> Void)?
        }
        let input: Input
        let output: [TagsUpdatesEntity]

        static let targetNodeRemoved = Arguments(
            input: .init(
                updatedNode: .init(changeTypes: [.removed], handle: Helper.targetNodeHandle),
                setupRepos: nil
            ),
            output: [.tagsInvalidated(node: Helper.targetNode)]
        )
        static let targetNodeInRubbishedBin = Arguments(
            input: .init(
                updatedNode: .init(changeTypes: [], handle: Helper.targetNodeHandle),
                setupRepos: { nodeRepo, _ in nodeRepo._isInRubbishBin = true }
            ),
            output: [.tagsInvalidated(node: Helper.targetNode)]
        )

        static let targetNodeTagsUpdated = Arguments(
            input: .init(
                updatedNode: .init(changeTypes: [.tags], handle: Helper.targetNodeHandle),
                setupRepos: nil
            ),
            output: [.tagsUpdated(node: Helper.targetNode)]
        )

        static let targetNodeAttributesUpdated = Arguments(
            input: .init(
                updatedNode: .init(changeTypes: [.attributes], handle: Helper.targetNodeHandle),
                setupRepos: nil
            ),
            output: []
        )

        static let nonTargetNodeRemovedWithoutTags = Arguments(
            input: .init(
                updatedNode: .init(changeTypes: [.removed], handle: 2, tags: []),
                setupRepos: nil
            ),
            output: []
        )

        static let nonTargetNodeRemovedWithTags = Arguments(
            input: .init(
                updatedNode: .init(changeTypes: [.removed], handle: 2, tags: ["x"]),
                setupRepos: nil
            ),
            output: [.tagsUpdated(node: Helper.targetNode)]
        )

        static let nonTargetNodeUpdatedWithTags = Arguments(
            input: .init(
                updatedNode: .init(changeTypes: [.tags], handle: 2),
                setupRepos: nil
            ),
            output: [.tagsUpdated(node: Helper.targetNode)]
        )
    }
}
