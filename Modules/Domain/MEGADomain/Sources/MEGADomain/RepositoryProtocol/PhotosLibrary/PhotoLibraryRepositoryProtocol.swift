import Foundation

public protocol PhotoLibraryRepositoryProtocol: Sendable {
    func photoSourceNode(for source: PhotoSourceEntity) async throws -> NodeEntity?
}
