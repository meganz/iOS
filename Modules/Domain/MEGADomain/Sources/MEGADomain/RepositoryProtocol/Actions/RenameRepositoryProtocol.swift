import Foundation

public protocol RenameRepositoryProtocol: RepositoryProtocol {
    func renameDevice(_ deviceId: String, newName: String) async throws
    func renameNode(_ node: NodeEntity, newName: String) async throws
    func parentNodeHasMatchingChild(_ parentNode: NodeEntity, childName: String) -> Bool
}
