public protocol NodeAttributeUseCaseProtocol: Sendable {
    func pathFor(node: NodeEntity) -> String?
    func numberChildrenFor(node: NodeEntity) -> Int
    func isInRubbishBin(node: NodeEntity) -> Bool
}

public struct NodeAttributeUseCase<T: NodeAttributeRepositoryProtocol>: NodeAttributeUseCaseProtocol {
    
    private let repo: T
    
    public init(repo: T) {
        self.repo = repo
    }
    
    public func pathFor(node: NodeEntity) -> String? {
        repo.pathFor(node: node)
    }
    
    public func numberChildrenFor(node: NodeEntity) -> Int {
        repo.numberChildrenFor(node: node)
    }
    
    public func isInRubbishBin(node: NodeEntity) -> Bool {
        repo.isInRubbishBin(node: node)
    }
}
