import Foundation
import Combine

public protocol AlbumContentsUseCaseProtocol {
    var updatePublisher: AnyPublisher<Void, Never> { get }
    
    func favouriteAlbumNodes() async throws -> [NodeEntity]
    func nodes(forAlbum album: AlbumEntity) async throws -> [NodeEntity]
}
