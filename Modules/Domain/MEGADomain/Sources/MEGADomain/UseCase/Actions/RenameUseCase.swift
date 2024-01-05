import Foundation

public protocol RenameUseCaseProtocol {
    func renameDevice(_ deviceId: String, newName: String) async throws
    func renameNode(_ node: NodeEntity, newName: String) async throws
    func parentNodeHasMatchingChild(_ parentNode: NodeEntity, childName: String) -> Bool
}

public struct RenameUseCase<Repository: RenameRepositoryProtocol>: RenameUseCaseProtocol {
    private let repository: Repository
    
    public init(renameRepository: Repository) {
        self.repository = renameRepository
    }
    
    public func renameDevice(_ deviceId: String, newName: String) async throws {
        try await repository.renameDevice(deviceId, newName: newName)
    }
    
    public func renameNode(_ node: NodeEntity, newName: String) async throws {
        try await repository.renameNode(node, newName: newName)
    }
    
    public func parentNodeHasMatchingChild(_ parentNode: NodeEntity, childName: String) -> Bool {
        repository.parentNodeHasMatchingChild(parentNode, childName: childName)
    }
}
