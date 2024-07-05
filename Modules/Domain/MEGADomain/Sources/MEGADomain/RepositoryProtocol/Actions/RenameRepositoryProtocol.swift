import Foundation

public protocol RenameRepositoryProtocol: RepositoryProtocol, Sendable {
    func renameDevice(_ deviceId: String, newName: String) async throws
}
