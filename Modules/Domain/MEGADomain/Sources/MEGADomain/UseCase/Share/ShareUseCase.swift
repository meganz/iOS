public protocol ShareUseCaseProtocol {
    func allPublicLinks(sortBy order: SortOrderEntity) -> [NodeEntity]
    func allOutShares(sortBy order: SortOrderEntity) -> [ShareEntity]
    func areCredentialsVerifed(of user: UserEntity) -> Bool
    func user(from node: NodeEntity) -> UserEntity?
    func createShareKeys(forNodes nodes: [NodeEntity]) async throws -> [HandleEntity]
    
    ///  Determines if the given sequence of Node Entities contains any sensitive elements or there descending children nodes are sensitive.
    /// - Parameter nodes: Sequence of NodeEntities to iterate over and determine if are sensitive or if its descendant nodes are sensitive
    /// - Returns: True, if any node contains descendant sensitive nodes, else false.
    func doesContainSensitiveDescendants(in nodes: some Sequence<NodeEntity>) async throws -> Bool
}

public struct ShareUseCase<T: ShareRepositoryProtocol, S: FilesSearchRepositoryProtocol>: ShareUseCaseProtocol {
    private let repo: T
    private let filesSearchRepository: S

    public init(repo: T, filesSearchRepository: S) {
        self.repo = repo
        self.filesSearchRepository = filesSearchRepository
    }
    
    public func allPublicLinks(sortBy order: SortOrderEntity) -> [NodeEntity] {
        repo.allPublicLinks(sortBy: order)
    }
    
    public func allOutShares(sortBy order: SortOrderEntity) -> [ShareEntity] {
        repo.allOutShares(sortBy: order)
    }

    public func areCredentialsVerifed(of user: UserEntity) -> Bool {
        repo.areCredentialsVerifed(of: user)
    }

    public func user(from node: NodeEntity) -> UserEntity? {
        repo.user(sharing: node)
    }
    
    public func createShareKeys(forNodes nodes: [NodeEntity]) async throws -> [HandleEntity] {
        try await withThrowingTaskGroup(of: HandleEntity.self, returning: [HandleEntity].self) { group in
            nodes.forEach { node in
                group.addTask {
                    return try await repo.createShareKey(forNode: node)
                }
            }
            
            return try await group.reduce(into: [HandleEntity](), { result, handle in
                result.append(handle)
            })
        }
    }
    
    public func doesContainSensitiveDescendants(in nodes: some Sequence<NodeEntity>) async throws -> Bool {
        try await withThrowingTaskGroup(of: Bool.self) { taskGroup in
            taskGroup.addTasksUnlessCancelled(for: nodes) { node in
                if node.isMarkedSensitive {
                    true
                } else if node.isFile {
                    false
                } else {
                    try await filesSearchRepository.search(filter: .recursive(
                        searchTargetLocation: .parentNode(node),
                        supportCancel: false,
                        sortOrderType: .defaultAsc,
                        formatType: .unknown,
                        sensitiveFilterOption: .sensitiveOnly)).isNotEmpty
                }
            }
            
            let doesNodeContainSensitiveChildren = try await taskGroup.contains(true)
            taskGroup.cancelAll()
            return doesNodeContainSensitiveChildren
        }
    }
}
