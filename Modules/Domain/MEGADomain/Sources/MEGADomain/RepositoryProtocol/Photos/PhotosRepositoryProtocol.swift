import Foundation

public protocol PhotosRepositoryProtocol: SharedRepositoryProtocol, Actor {
    func allPhotos() async throws -> [NodeEntity]
    func photo(forHandle handle: HandleEntity) async -> NodeEntity?
}
