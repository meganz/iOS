import Foundation
import MEGADomain
import Combine

public struct MockAlbumContentUseCase: AlbumContentsUseCaseProtocol {
    private let nodes: [NodeEntity]
    private let albumReloadPublisher: AnyPublisher<Void, Never>

    public init(nodes: [NodeEntity] = [],
                albumReloadPublisher: AnyPublisher<Void, Never> = Empty().eraseToAnyPublisher()) {
        self.nodes = nodes
        self.albumReloadPublisher = albumReloadPublisher
    }
    
    public func albumReloadPublisher(for type: AlbumEntityType) -> AnyPublisher<Void, Never> {
        albumReloadPublisher
    }
    
    public func favouriteAlbumNodes() async throws -> [NodeEntity] {
        nodes
    }
    
    public func nodes(forAlbum album: AlbumEntity) async throws -> [NodeEntity] {
        nodes
    }
}
