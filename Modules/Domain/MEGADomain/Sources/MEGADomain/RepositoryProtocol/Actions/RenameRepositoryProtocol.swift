import Foundation

public protocol RenameRepositoryProtocol: RepositoryProtocol {
    func renameDevice(_ deviceId: String, newName: String) async throws
}
