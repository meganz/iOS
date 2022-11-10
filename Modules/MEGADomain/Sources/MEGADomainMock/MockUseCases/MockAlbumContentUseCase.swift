import Foundation
import MEGADomain
import Combine

public struct MockAlbumContentUseCase: AlbumContentsUseCaseProtocol {
    public var updatePublisher: AnyPublisher<Void, Never>
    private var nodes = [NodeEntity]()

    public init(nodes: [NodeEntity]) {
        self.nodes = nodes
        updatePublisher = AnyPublisher(PassthroughSubject())
    }

    public func favouriteAlbumNodes() async throws -> [NodeEntity] {
        nodes
    }
    
    public func nodes(forAlbum album: AlbumEntity) async throws -> [NodeEntity] {
        nodes
    }
}
