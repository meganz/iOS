import MEGADomain

/// Records each action by the base64 handles of the nodes, and returns the node acted on.
actor MockFileProviderNodeActionRepository: NodeActionRepositoryProtocol {
    enum Action: Equatable {
        case createFolder(name: String, parent: String)
        case rename(String, name: String)
        case trash(String)
        case untrash(String)
        case move(String, parent: String)
        case delete(String)
    }

    static var newRepo: MockFileProviderNodeActionRepository { MockFileProviderNodeActionRepository() }

    private let createdFolder: NodeEntity
    private let error: (any Error)?
    private(set) var actions: [Action] = []

    /// - Parameters:
    ///   - createdFolder: What `createFolder` returns.
    ///   - error: What every action throws, when set.
    init(createdFolder: NodeEntity = NodeEntity(), error: (any Error)? = nil) {
        self.createdFolder = createdFolder
        self.error = error
    }

    func fetchNodes() async throws {}

    func createFolder(name: String, parent: NodeEntity) async throws -> NodeEntity {
        try perform(.createFolder(name: name, parent: parent.base64Handle))
        return createdFolder
    }

    func rename(node: NodeEntity, name: String) async throws -> NodeEntity {
        try perform(.rename(node.base64Handle, name: name))
        return node
    }

    func trash(node: NodeEntity) async throws -> NodeEntity {
        try perform(.trash(node.base64Handle))
        return node
    }

    func untrash(node: NodeEntity) async throws -> NodeEntity {
        try perform(.untrash(node.base64Handle))
        return node
    }

    func delete(node: NodeEntity) async throws {
        try perform(.delete(node.base64Handle))
    }

    func move(node: NodeEntity, toParent: NodeEntity) async throws -> NodeEntity {
        try perform(.move(node.base64Handle, parent: toParent.base64Handle))
        return node
    }

    func removeLink(nodes: [NodeEntity]) async throws {}

    func setSensitive(node: NodeEntity, sensitive: Bool) async throws -> NodeEntity {
        node
    }

    private func perform(_ action: Action) throws {
        if let error {
            throw error
        }
        actions.append(action)
    }
}
