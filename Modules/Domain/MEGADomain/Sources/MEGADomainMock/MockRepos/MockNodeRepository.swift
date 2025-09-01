import Foundation
import MEGADomain
import MEGASwift

public final class MockNodeRepository: NodeRepositoryProtocol, @unchecked Sendable {
    public static var newRepo: MockNodeRepository { MockNodeRepository() }
    
    public let nodeUpdates: AnyAsyncSequence<[NodeEntity]>
    public let folderLinkNodeUpdates: AnyAsyncSequence<[NodeEntity]>
    private let node: NodeEntity?
    private let rubbishBinNode: NodeEntity?
    private let nodeRoot: NodeEntity?
    private let nodeAccessLevel: NodeAccessTypeEntity
    private let childNodeNamed: NodeEntity?
    private let childNode: NodeEntity?
    private let fileLinkNode: NodeEntity?
    private let childNodes: [String: NodeEntity]
    @Atomic public var childrenNodes: [NodeEntity] = []
    private let parentNodes: [NodeEntity]
    private let isInheritingSensitivityResult: Result<Bool, any Error>
    private let isInheritingSensitivityResults: [NodeEntity: Result<Bool, any Error>]
    private let isInRubbishBinNodes: [NodeEntity]
    private let isNodeDecryptedValue: Bool?

    public init(
        node: NodeEntity? = nil,
        rubbishBinNode: NodeEntity? = nil,
        nodeRoot: NodeEntity? = nil,
        nodeAccessLevel: NodeAccessTypeEntity = .unknown,
        childNodeNamed: NodeEntity? = nil,
        childNode: NodeEntity? = nil,
        fileLinkNode: NodeEntity? = nil,
        childNodes: [String: NodeEntity] = [:],
        childrenNodes: [NodeEntity] = [],
        parentNodes: [NodeEntity] = [],
        isInheritingSensitivityResult: Result<Bool, any Error> = .failure(GenericErrorEntity()),
        isInheritingSensitivityResults: [NodeEntity: Result<Bool, any Error>] = [:],
        nodeUpdates: AnyAsyncSequence<[NodeEntity]> = EmptyAsyncSequence().eraseToAnyAsyncSequence(),
        folderLinkNodeUpdates: AnyAsyncSequence<[NodeEntity]> = EmptyAsyncSequence().eraseToAnyAsyncSequence(),
        isInRubbishBinNodes: [NodeEntity] = [],
        isNodeDecryptedValue: Bool? = false
    ) {
        self.node = node
        self.rubbishBinNode = rubbishBinNode
        self.nodeRoot = nodeRoot
        self.nodeAccessLevel = nodeAccessLevel
        self.childNodeNamed = childNodeNamed
        self.childNode = childNode
        self.fileLinkNode = fileLinkNode
        self.childNodes = childNodes
        self.parentNodes = parentNodes
        self.isInheritingSensitivityResult = isInheritingSensitivityResult
        self.isInheritingSensitivityResults = isInheritingSensitivityResults
        self.nodeUpdates = nodeUpdates
        self.folderLinkNodeUpdates = folderLinkNodeUpdates
        self.isInRubbishBinNodes = isInRubbishBinNodes
        self.isNodeDecryptedValue = isNodeDecryptedValue
        $childrenNodes.mutate { $0 = childrenNodes }

    }
    
    public func nodeForHandle(_ handle: HandleEntity) -> NodeEntity? {
        node
    }
    
    public func nodeFor(fileLink: FileLinkEntity) async throws -> NodeEntity {
        guard let node = fileLinkNode else {
            throw NodeErrorEntity.nodeNotFound
        }
        return node
    }
    
    public func childNodeNamed(name: String, in parentHandle: HandleEntity) -> NodeEntity? {
        childNode
    }
    
    public func childNode(parent node: NodeEntity,
                          name: String,
                          type: NodeTypeEntity) async -> NodeEntity? {
        childNodes[name]
    }
    
    public func rubbishNode() -> NodeEntity? {
        rubbishBinNode
    }
    
    public func rootNode() -> NodeEntity? {
        nodeRoot
    }
    
    public func parents(of node: NodeEntity) async -> [NodeEntity] {
        parentNodes
    }
    
    public func asyncChildren(of node: NodeEntity) async -> [NodeEntity] {
        childrenNodes
    }
    
    public func children(of node: NodeEntity) -> NodeListEntity? {
        .init(nodesCount: 0, nodeAt: { _ in nil })
    }

    public func asyncChildren(of node: NodeEntity, sortOrder: SortOrderEntity) async -> NodeListEntity? {
        guard !childrenNodes.isEmpty else { return nil }
        return .init(nodesCount: childrenNodes.count, nodeAt: { index in
            return self.childrenNodes[index]
        })
    }

    public func childrenNames(of node: NodeEntity) -> [String]? {
        childrenNodes.compactMap {$0.name}
    }

    public func isInRubbishBin(node: NodeEntity) -> Bool {
        isInRubbishBinNodes.contains { $0 == node }
    }

    public func createFolder(with name: String, in parent: NodeEntity) async throws -> NodeEntity {
        parent
    }
    
    public func isInheritingSensitivity(node: NodeEntity) async throws -> Bool {
        try await withCheckedThrowingContinuation {
            guard let result = isInheritingSensitivityResults[node] else {
                return $0.resume(with: isInheritingSensitivityResult)
            }
            return $0.resume(with: result)
        }
    }
    
    public func isInheritingSensitivity(node: NodeEntity) throws -> Bool {
        let result = isInheritingSensitivityResults[node] ?? isInheritingSensitivityResult
        return switch result {
        case .success(let isSensitive):
           isSensitive
        case .failure(let error):
            throw error
        }
    }

    public func isNodeDecrypted(node: MEGADomain.NodeEntity) throws -> Bool {
        guard let isNodeDecryptedValue else {
            throw NodeErrorEntity.nodeNotFound
        }
        return isNodeDecryptedValue
    }
}
