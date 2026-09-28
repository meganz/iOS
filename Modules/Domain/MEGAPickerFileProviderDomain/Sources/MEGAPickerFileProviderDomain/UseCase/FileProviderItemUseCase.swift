import FileProvider
import MEGADomain

public protocol FileProviderItemUseCaseProtocol: Sendable {
    /// The item for `identifier`, which is `.rootContainer`, `.trashContainer` or a node's base64 handle.
    /// - Throws: `NSFileProviderError(.noSuchItem)` when no node in the cloud drive or the rubbish bin matches.
    func item(for identifier: NSFileProviderItemIdentifier) throws -> FileProviderItemEntity

    /// One page of the children of a container, leaving out sensitive nodes.
    /// - Parameters:
    ///   - containerIdentifier: `.rootContainer`, `.trashContainer` or a folder node's base64 handle.
    ///   - page: The offset of the first child to return and how many to return at most.
    /// - Throws: `NSFileProviderError(.noSuchItem)` when the container is not a folder that exists.
    func children(of containerIdentifier: NSFileProviderItemIdentifier, page: SearchPageEntity) async throws -> [FileProviderItemEntity]
}

public struct FileProviderItemUseCase<
    S: FilesSearchRepositoryProtocol,
    T: NodeRepositoryProtocol,
    U: MEGAHandleRepositoryProtocol,
    V: NodeAttributeRepositoryProtocol
>: FileProviderItemUseCaseProtocol {
    private let filesSearchRepo: S
    private let nodeRepo: T
    private let megaHandleRepo: U
    private let nodeAttributeRepo: V

    public init(filesSearchRepo: S, nodeRepo: T, megaHandleRepo: U, nodeAttributeRepo: V) {
        self.filesSearchRepo = filesSearchRepo
        self.nodeRepo = nodeRepo
        self.megaHandleRepo = megaHandleRepo
        self.nodeAttributeRepo = nodeAttributeRepo
    }

    public func item(for identifier: NSFileProviderItemIdentifier) throws -> FileProviderItemEntity {
        switch identifier {
        case .rootContainer, .trashContainer:
            return makeItem(identifier: identifier, parentIdentifier: .rootContainer, node: try containerNode(for: identifier))
        default:
            let node = try node(for: identifier)
            return makeItem(identifier: identifier, parentIdentifier: try parentIdentifier(of: node), node: node)
        }
    }

    public func children(of containerIdentifier: NSFileProviderItemIdentifier, page: SearchPageEntity) async throws -> [FileProviderItemEntity] {
        let container = try containerNode(for: containerIdentifier)
        guard container.isFolder else {
            throw NSFileProviderError(.noSuchItem)
        }
        let children: [NodeEntity] = try await filesSearchRepo.search(
            filter: .nonRecursive(
                searchText: nil,
                searchTargetNode: container,
                supportCancel: false,
                sortOrderType: .defaultAsc,
                formatType: .unknown,
                sensitiveFilterOption: .nonSensitiveOnly
            ),
            page: page
        )
        // Every child of a container has the container as its parent, so the parent never has to be looked up.
        return children.map {
            makeItem(identifier: NSFileProviderItemIdentifier($0.base64Handle), parentIdentifier: containerIdentifier, node: $0)
        }
    }

    // MARK: - Private

    /// Like the legacy extension, the child count includes sensitive children the enumeration leaves out. Files only
    /// shows a folder's count once the folder has been opened: it counts the children on disk, and an unopened
    /// folder is dataless.
    private func makeItem(
        identifier: NSFileProviderItemIdentifier,
        parentIdentifier: NSFileProviderItemIdentifier,
        node: NodeEntity
    ) -> FileProviderItemEntity {
        FileProviderItemEntity(
            identifier: identifier,
            parentIdentifier: parentIdentifier,
            node: node,
            childCount: node.isFolder ? nodeAttributeRepo.numberChildrenFor(node: node) : nil
        )
    }

    private func containerNode(for identifier: NSFileProviderItemIdentifier) throws -> NodeEntity {
        let node = switch identifier {
        case .rootContainer: nodeRepo.rootNode()
        case .trashContainer: nodeRepo.rubbishNode()
        default: try? self.node(for: identifier)
        }
        guard let node else {
            throw NSFileProviderError(.noSuchItem)
        }
        return node
    }

    private func node(for identifier: NSFileProviderItemIdentifier) throws -> NodeEntity {
        guard let handle = megaHandleRepo.handle(forBase64Handle: identifier.rawValue),
              let node = nodeRepo.nodeForHandle(handle) else {
            throw NSFileProviderError(.noSuchItem)
        }
        return node
    }

    /// Nodes are only served from the cloud drive and the rubbish bin, whose own nodes are the two containers.
    private func parentIdentifier(of node: NodeEntity) throws -> NSFileProviderItemIdentifier {
        if let rootNode = nodeRepo.rootNode(), node.parentHandle == rootNode.handle {
            return .rootContainer
        }
        if let rubbishNode = nodeRepo.rubbishNode(), node.parentHandle == rubbishNode.handle {
            return .trashContainer
        }
        guard let parent = nodeRepo.nodeForHandle(node.parentHandle) else {
            throw NSFileProviderError(.noSuchItem)
        }
        return NSFileProviderItemIdentifier(parent.base64Handle)
    }
}
