import MEGADomain
import Foundation

public final class MockAlbumRepository: AlbumRepositoryProtocol {
    var node: NodeEntity?
    
    public static var newRepo: MockAlbumRepository {
        MockAlbumRepository(node: NodeEntity(handle: 1))
    }
    
    public init(node: NodeEntity?) {
        self.node = node
    }

    public func loadCameraUploadNode() async throws -> NodeEntity? {
        node
    }
}
